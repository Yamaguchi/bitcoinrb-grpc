module Bitcoin
  module Wallet
    class UtxoHandler < Concurrent::Actor::Context
      include Events
      attr_reader :watchings, :spv, :utxo_db, :publisher

      def initialize(spv, publisher)
        @watchings = []
        @spv = spv
        @spv.add_observer(self)

        @utxo_db = spv.wallet.utxo_db
        @publisher = publisher
      end

      def update(event, data)
        puts "udpate:#{event}"
        send(event, data)
      end

      def on_message(message)
        case message
        when WatchTxConfirmed
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
          utxo = utxo_db.save_utxo(out_point, output.value, output.script_pubkey, block_height)
          publisher << EventUtxoRegistered.new(tx, utxo) if utxo
        end

        tx.inputs.each do |input|
          utxo = utxo_db.delete_utxo(input.out_point)
          publisher << EventUtxoSpent.new(tx, utxo) if utxo
        end

        publisher << WatchAssetIdAssigned.new(tx) if tx.colored?
      end

      def merkleblock(data)
        block_height = spv.chain.latest_block.height
        tree = Bitcoin::MerkleTree.build_partial(data.tx_count, data.hashes, Bitcoin.byte_to_bit(data.flags.htb))
        tx_blockhash = data.header.block_hash

        watchings
          .select { |item| item.is_a? WatchTxConfirmed }
          .select { |item| data.hashes.include?(item.tx.tx_hash) }
          .each do |item|
            tx_index = tree.find_node(item.tx.tx_hash).index
            next unless tx_index
            utxo_db.save_tx(item.tx, block_height, tx_index)
          end
      end

      def header(data)
        block_height = data[:height]
        watchings.select do |item|
          case item
          when WatchTxConfirmed
            height, tx_index = utxo_db.get_tx_position(item.tx.tx_hash)
            publisher << EventTxConfirmed.new(item.tx, item.confirmations) if block_height >= height + item.confirmations
            watchings.delete(item)
          else
          end
        end
      end
    end
  end
end
