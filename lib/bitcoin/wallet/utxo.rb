module Bitcoin
  module Wallet
    class Utxo
      attr_reader :tx_hash
      attr_reader :index
      attr_reader :block_height
      attr_reader :value
      attr_reader :script_pubkey

      def initialize(tx_hash, index, block_height, value: 0, script_pubkey: nil)
        @tx_hash = tx_hash
        @index = index
        @block_height = block_height
        @value = value
        @script_pubkey = script_pubkey
      end

      def self.parse_from_payload(payload)
        buf = payload.is_a?(String) ? StringIO.new(payload) : payload
        tx_hash, index, block_height, value = buf.read(48).unpack('H64N2Q>')
        len = Bitcoin.unpack_var_int_from_io(buf)
        script_payload = buf.read(len)
        script_pubkey = Bitcoin::Script.parse_from_payload(script_payload)
        new(tx_hash, index, block_height, value: value, script_pubkey: script_pubkey)
      end

      def to_payload
        payload = +''
        payload << tx_hash.htb
        payload << [index, block_height, value].pack('N2Q>')
        script_payload = script_pubkey.to_payload
        payload << Bitcoin.pack_var_int(script_payload.bytesize)
        payload << script_payload
        payload
      end
    end
  end
end
