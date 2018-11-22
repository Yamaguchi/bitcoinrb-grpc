module Bitcoin
  module Wallet
    class AssetOutput
      attr_reader :asset_type
      attr_reader :asset_id
      attr_reader :asset_quantity
      attr_reader :tx_hash
      attr_reader :index

      def initialize(asset_type, asset_id, asset_quantity, tx_hash, index, block_height)
        @asset_type = asset_type
        @asset_id = asset_id
        @asset_quantity = asset_quantity
        @tx_hash = tx_hash
        @index = index
      end

      def self.parse_from_payload(payload)
        buf = payload.is_a?(String) ? StringIO.new(payload) : payload
        asset_type, asset_quantity, tx_hash, index, len = buf.read(45).unpack('Cq>H64N2')
        asset_id = buf.read(len)
        new(asset_type, asset_id, asset_quantity, tx_hash, index)
      end

      def to_payload
        payload = +''
        payload << [asset_type, asset_quantity, tx_hash, index, len].pack('Cq>H64N2')
        payload << asset_id
        payload
      end
    end
  end
end
