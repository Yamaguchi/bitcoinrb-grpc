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
          utxo_db.delete_token(AssetFeature::AssetType::OPEN_ASSETS, message.utxo) if tx.open_assets?
        when Bitcoin::Grpc::WatchAssetIdAssignedRequest
          tx = Bitcoin::Tx.parse_from_payload(message.tx_payload.htb)
          case
          when tx.open_assets?
            outputs = outputs_with_open_asset_id(message.tx_hash)
            if outputs
              outputs.each do |output|
                asset_id = output['asset_id']
                asset_quantity = output['asset_quantity']

                next unless asset_id
                utxo_db.save_token(AssetFeature::AssetType::OPEN_ASSETS, asset_id, asset_quantity, message.utxo)
                if oa_output_type == 'issuance'
                  publisher << Bitcoin::Grpc::EventTokenIssued.new(asset_type: AssetFeature::AssetType::OPEN_ASSETS, asset_id: asset_id, asset_quantity: asset_quantity)
                else
                  publisher << Bitcoin::Grpc::EventTokenTransfered.new(asset_type: AssetFeature::AssetType::OPEN_ASSETS, asset_id: asset_id, asset_quantity: asset_quantity)
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

      def outputs_with_open_asset_id(tx_hash)
        client = JSONClient.new
        client.debug_dev = STDOUT

        response = client.get("#{oae_url}#{tx_hash.rhex}?format=json")
        response.body['outputs']
      rescue RuntimeError => _
        nil
      end

      def oae_url
        case
        when Bitcoin.chain_params.mainnet?
          'https://www.oaexplorer.com/tx/'
        when Bitcoin.chain_params.testnet?
          'https://testnet.oaexplorer.com/tx/'
        when Bitcoin.chain_params.regtest?
          'http://localhost:9292/tx/'
        end
      end
    end
  end
end
