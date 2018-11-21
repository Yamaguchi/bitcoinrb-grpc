module Bitcoin
  module Wallet
    class UtxoDB

      KEY_PREFIX = {
        out_point: 'o',  # key: out_point(tx_hash and index)
        script: 's',     # key: script_pubkey and out_point(tx_hash and index)
        block: 'b',      # key: block height and tx_index(position in block)
      }

      attr_reader :level_db

      def initialize(path = "#{Bitcoin.base_dir}/db/utxo")
        FileUtils.mkdir_p(path)
        @level_db = ::LevelDB::DB.new(path)
      end

      def close
        level_db.close
      end

      def save(out_point, value, script_pubkey, block_height, tx_index)
        level_db.batch do
          utxo = Bitcoin::Wallet::Utxo.new(out_point.txid.rhex, out_point.index, block_height, tx_index, value: value, script_pubkey: script_pubkey)
          payload = utxo.to_payload.bth

          # out_point
          key = KEY_PREFIX[:out_point] + out_point.to_payload.bth
          level_db.put(key, payload)

          # script_pubkey
          if script_pubkey
            key = KEY_PREFIX[:script] + script_pubkey.to_payload.bth + out_point.to_payload.bth
            level_db.put(key, payload)
          end

          # block
          key = KEY_PREFIX[:block] + [block_height, tx_index].pack('N2').bth
          level_db.put(key, payload)
        end
      end

      def delete(out_point)
        level_db.batch do
          key = KEY_PREFIX[:out_point] + out_point.to_payload.bth
          utxo = Utxo.parse_from_payload(level_db.get(key).htb)
          level_db.delete(key)

          if utxo.script_pubkey
            key = KEY_PREFIX[:script] + utxo.script_pubkey.to_payload.bth + out_point.to_payload.bth
            level_db.delete(key)
          end

          key = KEY_PREFIX[:block] + [utxo.block_height, utxo.tx_index].pack('N2').bth
          level_db.delete(key)
        end
      end

      def list_unspent(block_min: 0, block_max: 9999999, addresses: nil)
        if addresses
          list_unspent_by_addresses(block_min: block_min, block_max: block_max, addresses: addresses)
        else
          list_unspent_by_block_height(block_min: block_min, block_max: block_max)
        end
      end

      def get_balance(account)
        list_unspent_by_script_pubkeys(script_pubkeys: account.watch_targets.map { |t| Bitcoin::Script.to_p2wpkh(t).to_payload.bth }).sum { |u| u.value }
      end

      private

      def list_unspent_by_block_height(block_min: 0, block_max: 9999999)
        from = KEY_PREFIX[:block] + [block_min].pack('N').bth + '00000000'
        to = KEY_PREFIX[:block] + [block_max].pack('N').bth + 'ffffffff'
        level_db.each(from: from, to: to).map { |k, v| Bitcoin::Wallet::Utxo.parse_from_payload(v.htb) }
      end

      def list_unspent_by_addresses(block_min: 0, block_max: 9999999, addresses: [])
        script_pubkeys = addresses.map { |a| Bitcoin::Script.parse_from_addr(a).to_payload.bth }
        list_unspent_by_script_pubkeys(block_min: block_min, block_max: block_max, script_pubkeys: script_pubkeys)
      end

      def list_unspent_by_script_pubkeys(block_min: 0, block_max: 9999999, script_pubkeys: [])
        script_pubkeys.map do |key|
          from = KEY_PREFIX[:script] + key + '000000000000000000000000000000000000000000000000000000000000000000000000'
          to = KEY_PREFIX[:script] + key + 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'
          level_db.each(from: from, to: to).map { |k, v| Bitcoin::Wallet::Utxo.parse_from_payload(v.htb) }.select { |u| u.block_height >= block_min && u.block_height <= block_max }
        end.flatten
      end
    end
  end
end
