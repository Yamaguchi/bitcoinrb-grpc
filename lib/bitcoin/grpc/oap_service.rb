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
        @@config ||= load_config
        @@config['url']
      end

      def self.load_config
        file = 'config.yml'
        yml = YAML.load_file(file)
        config = yml['open_assets_explorer']
        raise "config.yml should contain 'open_assets_explorer' section." unless config
        config
      end
    end
  end
end
