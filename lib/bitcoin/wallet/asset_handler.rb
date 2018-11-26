# frozen_string_literal: true

require 'jsonclient'

module Bitcoin
  module Wallet
    class AssetHandler < Concurrent::Actor::RestartingContext
      include Events

      attr_reader :utxo_db, :publisher

      def initialize(spv, publisher)
        publisher << [:subscribe, EventUtxoSpent]
        publisher << [:subscribe, WatchAssetIdAssigned]
        @publisher = publisher
        @utxo_db = spv.wallet.utxo_db
      end

      def on_message(message)
        case message
        when EventUtxoSpent
          utxo_db.delete_token(AssetFeature::AssetType::OPEN_ASSETS, message.utxo) if message.tx.open_assets?
        when WatchAssetIdAssigned
          case
          when message.tx.open_assets?
            outputs = outputs_with_open_asset_id(message.tx.txid)
            if outputs
              outputs.each do |output|
                asset_id = output['asset_id']
                asset_quantity = output['asset_quantity']
                next unless asset_id
                utxo_db.save_token(AssetFeature::AssetType::OPEN_ASSETS, asset_id, asset_quantity, message.utxo)
                publisher << EventTokenRegistered.new(:open_assets, asset_id, asset_quantity)
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

      private

      def outputs_with_open_asset_id(txid)
        client = JSONClient.new
        client.debug_dev = STDOUT

        response = client.get("#{oae_url}#{txid}?format=json")
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
