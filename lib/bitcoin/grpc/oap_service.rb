require 'jsonclient'

module Bitcoin
  module Grpc
    module OapService
      def self.outputs_with_open_asset_id(tx_hash)
        client = JSONClient.new
        client.debug_dev = STDOUT

        response = client.get("#{oae_url}#{tx_hash.rhex}?format=json")
        response.body['outputs']
      rescue RuntimeError => _
        nil
      end

      def self.oae_url
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