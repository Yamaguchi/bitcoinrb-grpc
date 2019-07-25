# frozen_string_literal: true

module Bitcoin
  module Wallet
    class AssetHandler < Concurrent::Actor::RestartingContext
      attr_reader :utxo_db, :publisher, :watchings

      def initialize(spv, publisher)
        publisher << [:subscribe, Bitcoin::Grpc::EventUtxoSpent]
        publisher << [:subscribe, Bitcoin::Grpc::WatchAssetIdAssignedRequest]
        @publisher = publisher
        @utxo_db = spv.wallet.utxo_db
        @logger = Bitcoin::Logger.create(:debug)
        @watchings = []
      end

      def on_message(message)
        case message
        when Bitcoin::Grpc::WatchTokenRequest
          watchings << message
        when Bitcoin::Grpc::EventUtxoSpent
          tx = Bitcoin::Tx.parse_from_payload(message.tx_payload.htb)
          log(::Logger::DEBUG, "tx=#{tx}, open_assets?=#{tx.open_assets?}")
          utxo_db.delete_token(message.utxo) if tx.open_assets?
        when Bitcoin::Grpc::WatchAssetIdAssignedRequest
          tx = Bitcoin::Tx.parse_from_payload(message.tx_payload.htb)
          log(::Logger::DEBUG, "tx=#{tx}, open_assets?=#{tx.open_assets?}")
          case
          when tx.open_assets?
            outputs = Bitcoin::Grpc::OapService.outputs_with_open_asset_id(message.tx_hash)
            begin
              if outputs
                outputs.each do |output|
                  asset_id = output['asset_id']
                  next unless asset_id

                  asset_id_as_hex = Bitcoin::Base58.decode(asset_id)
                  asset_quantity = output['asset_quantity']
                  oa_output_type = output['oa_output_type']

                  out_point = Bitcoin::OutPoint.new(tx.tx_hash, output['n'])
                  utxo = utxo_db.get_utxo(out_point)
                  next unless utxo

                  asset_output = utxo_db.save_token(AssetFeature::AssetType::OPEN_ASSETS, asset_id_as_hex, asset_quantity, utxo)
                  next unless asset_output

                  item_to_delete = []
                  watchings.select { |item| item.asset_id == asset_id && tx.tx_hash == item.tx_hash }.each do |item|
                    if oa_output_type == 'issuance'
                      publisher << Bitcoin::Grpc::EventTokenIssued.new(request_id: item.id, asset: asset_output)
                    else
                      publisher << Bitcoin::Grpc::EventTokenTransfered.new(request_id: item.id, asset: asset_output)
                    end
                    item_to_delete << item
                  end
                  item_to_delete.each { |item| watchings.delete(item) }
                end
              else
                raise 'can not get asset_id'
              end
            rescue => e
              log(::Logger::DEBUG, e.message)
              log(::Logger::DEBUG, e.backtrace)
              task = Concurrent::TimerTask.new(execution_interval: 60) do
                self << message
                task.shutdown
              end
              task.execute
            end
          else
          end
        end
      end
    end
  end
end
