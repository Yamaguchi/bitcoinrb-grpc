# frozen_string_literal: true

require 'jsonclient'

module Bitcoin
  module Wallet
    class AssetHandler < Concurrent::Actor::RestartingContext
      attr_reader :utxo_db, :publisher

      def initialize(spv, publisher)
        publisher << [:subscribe, Bitcoin::Grpc::EventUtxoSpent]
        publisher << [:subscribe, Bitcoin::Grpc::WatchAssetIdAssignedRequest]
        @publisher = publisher
        @utxo_db = spv.wallet.utxo_db
      end

      def on_message(message)
        case message
        when Bitcoin::Grpc::EventUtxoSpent
          tx = Bitcoin::Tx.parse_from_payload(message.tx_payload.htb)
          utxo_db.delete_token(message.utxo) if tx.open_assets?
        when Bitcoin::Grpc::WatchAssetIdAssignedRequest
          tx = Bitcoin::Tx.parse_from_payload(message.tx_payload.htb)
          case
          when tx.open_assets?
            outputs = Bitcoin::Grpc::OapService.outputs_with_open_asset_id(message.tx_hash)
            if outputs
              outputs.each do |output|
                asset_id = output['asset_id']
                asset_quantity = output['asset_quantity']
                oa_output_type = output['oa_output_type']
                next unless asset_id
                out_point = Bitcoin::OutPoint.new(tx.tx_hash, output['n'])
                utxo = utxo_db.get_utxo(out_point)
                next unless utxo
                asset_output = utxo_db.save_token(AssetFeature::AssetType::OPEN_ASSETS, asset_id, asset_quantity, utxo)
                if oa_output_type == 'issuance'
                  publisher << Bitcoin::Grpc::EventTokenIssued.new(asset: asset_output)
                else
                  publisher << Bitcoin::Grpc::EventTokenTransfered.new(asset: asset_output)
                end
              end
            else
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
