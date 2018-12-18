module Bitcoin
  module Wallet
    class DB
      def save_key(account, purpose, index, key)
        pubkey = key.pub
        id = [account.purpose, account.index, purpose, index].pack('I*').bth
        k = KEY_PREFIX[:key] + id
        script_pubkey = Bitcoin::Script.to_p2wpkh(Bitcoin.hash160(pubkey)).to_payload.bth
        k2 = 'p' + script_pubkey
        level_db.put(k, pubkey)
        level_db.put(k2, id)
        key
      end

      def get_key_index(script_pubkey)
        k = 'p' + script_pubkey
        id = level_db.get(k)
        return unless id
        id.htb.unpack('I*')
      end
    end
  end
end
