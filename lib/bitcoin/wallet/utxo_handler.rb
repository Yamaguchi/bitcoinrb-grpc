module Bitcoin
  module Wallet
    class UtxoHandler < Concurrent::Actor::Context
      attr_reader :watchings, :spv, :utxo_db, :publisher

      def initialize(spv, publisher)
        @watchings = []
        @spv = spv
        @spv.add_observer(self)

        @utxo_db = spv.wallet.utxo_db
        @publisher = publisher
      end

      def update(event, data)
        send(event, data)
      end

      def on_message(message)
        case message
        when Bitcoin::Grpc::WatchTxConfirmedRequest
          spv.filter_add(message.tx_hash)
          watchings << message
        when :watchings
          watchings
        end
      end

      private

      def tx(data)
        tx = data.tx
        block_height = spv.chain.latest_block.height
        watch_targets = spv.wallet.watch_targets

        tx.outputs.each_with_index do |output, index|
          next unless watch_targets.find { |target| output.script_pubkey == Bitcoin::Script.to_p2wpkh(target) }
          out_point = Bitcoin::OutPoint.new(tx.tx_hash, index)
          utxo = utxo_db.save_utxo(out_point, output.value, output.script_pubkey.to_payload.bth, block_height)
          publisher << Bitcoin::Grpc::EventUtxoRegistered.new(tx_hash: tx.tx_hash, tx_payload: tx.to_payload.bth, utxo: utxo) if utxo
        end

        tx.inputs.each do |input|
          utxo = utxo_db.delete_utxo(input.out_point)
          publisher << Bitcoin::Grpc::EventUtxoSpent.new(tx_hash: tx.tx_hash, tx_payload: tx.to_payload.bth, utxo: utxo) if utxo
        end

        utxo_db.save_tx(tx.tx_hash, tx.to_payload.bth)

        publisher << Bitcoin::Grpc::WatchAssetIdAssignedRequest.new(tx_hash: tx.tx_hash, tx_payload: tx.to_payload.bth) if tx.colored?
      end

      def merkleblock(data)
        block_height = spv.chain.latest_block.height
        tree = Bitcoin::MerkleTree.build_partial(data.tx_count, data.hashes, Bitcoin.byte_to_bit(data.flags.htb))
        tx_blockhash = data.header.block_hash

        log(::Logger::DEBUG, "UtxoHandler#merkleblock:#{data.hashes}")

        watchings
          .select { |item| item.is_a? Bitcoin::Grpc::WatchTxConfirmedRequest }
          .select { |item| data.hashes.include?(item.tx_hash) }
          .each do |item|
            tx_index = tree.find_node(item.tx_hash).index
            log(::Logger::DEBUG, "UtxoHandler#merkleblock:#{[tx_index]}")
            next unless tx_index
            utxo_db.save_tx_position(item.tx_hash, block_height, tx_index)
          end
      end

      def header(data)
        log(::Logger::DEBUG, "UtxoHandler#header:#{[data, watchings]}")
        block_height = data[:height]
        watchings.select do |item|
          case item
          when Bitcoin::Grpc::WatchTxConfirmedRequest
            height, tx_index, tx_payload = utxo_db.get_tx(item.tx_hash)
            log(::Logger::DEBUG, "UtxoHandler#header:#{[height, tx_index]}")
            next unless (height || tx_index)
            if block_height >= height + item.confirmations
              publisher << Bitcoin::Grpc::EventTxConfirmed.new(tx_hash: item.tx_hash, tx_payload: tx_payload, block_height: height, tx_index: tx_index, confirmations: item.confirmations)
              watchings.delete(item)
            end
          else
          end
        end
      end
    end
  end
end
