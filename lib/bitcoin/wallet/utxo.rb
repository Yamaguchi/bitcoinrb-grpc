module Bitcoin
  module Wallet
    class Utxo
      attr_reader :txid
      attr_reader :index
      attr_reader :block_height
      attr_reader :tx_index
      attr_reader :value
      attr_reader :script_pubkey

      def initialize(txid, index, block_height, tx_index, value: 0, script_pubkey: nil)
        @txid = txid
        @index = index
        @block_height = block_height
        @tx_index = tx_index
        @value = value
        @script_pubkey = script_pubkey
      end

      def self.parse_from_payload(payload)
        buf = payload.is_a?(String) ? StringIO.new(payload) : payload
        txid, index, block_height, tx_index, value = buf.read(52).unpack('H64N3Q>')
        len = Bitcoin.unpack_var_int_from_io(buf)
        script_payload = buf.read(len)
        script_pubkey = Bitcoin::Script.parse_from_payload(script_payload)
        new(txid, index, block_height, tx_index, value, script_pubkey)
      end

      def to_payload
        payload = +''
        payload << txid.htb
        payload << [index, block_height, tx_index, value].pack('N3Q>')
        script_payload = script_pubkey.to_payload
        payload << Bitcoin.pack_var_int(script_payload.bytesize)
        payload << script_payload
        payload
      end
    end
  end
end
