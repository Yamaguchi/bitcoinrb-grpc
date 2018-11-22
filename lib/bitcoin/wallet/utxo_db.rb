module Bitcoin
  module Wallet
    class UtxoDB

      KEY_PREFIX = {
        out_point: 'o',  # key: out_point(tx_hash and index), value: Utxo
        script: 's',     # key: script_pubkey and out_point(tx_hash and index), value: Utxo
        height: 'h',     # key: block_height and out_point, value: Utxo
        tx_hash: 't',    # key: tx_hash of transaction, value: Tx
        block: 'b',      # key: block_height and tx_index, value: Tx
      }

      attr_reader :level_db

      def initialize(path = "#{Bitcoin.base_dir}/db/tx")
        FileUtils.mkdir_p(path)
        @level_db = ::LevelDB::DB.new(path)
      end

      def close
        level_db.close
      end

      def save_tx(tx, block_height, tx_index)
        level_db.batch do
          # tx_hash -> [block_height, tx_index]
          key = KEY_PREFIX[:tx_hash] + tx.tx_hash
          level_db.put(key, [block_height, tx_index].pack('N2').bth)

          # block_hash and tx_index
          key = KEY_PREFIX[:block] + [block_height, tx_index].pack('N2').bth
          level_db.put(key, tx.to_payload.bth)
        end
      end

      # @return [block_height, tx_index]
      def get_tx_position(tx_hash)
        key = KEY_PREFIX[:tx_hash] + tx_hash
        level_db.get(key).unpack('N2')
      end

      def save_utxo(out_point, value, script_pubkey, block_height)
        level_db.batch do
          utxo = Bitcoin::Wallet::Utxo.new(out_point.txid.rhex, out_point.index, block_height, value: value, script_pubkey: script_pubkey)
          payload = utxo.to_payload.bth

          # out_point
          key = KEY_PREFIX[:out_point] + out_point.to_payload.bth
          return if level_db.contains?(key)
          level_db.put(key, payload)

          # script_pubkey
          if script_pubkey
            key = KEY_PREFIX[:script] + script_pubkey.to_payload.bth + out_point.to_payload.bth
            level_db.put(key, payload)
          end

          # block_height
          key = KEY_PREFIX[:height] + [block_height].pack('N').bth + out_point.to_payload.bth
          level_db.put(key, payload)
        end
      end

      def delete_utxo(out_point)
        level_db.batch do
          key = KEY_PREFIX[:out_point] + out_point.to_payload.bth
          return unless level_db.contains?(key)
          utxo = Utxo.parse_from_payload(level_db.get(key).htb)
          level_db.delete(key)

          if utxo.script_pubkey
            key = KEY_PREFIX[:script] + utxo.script_pubkey.to_payload.bth + out_point.to_payload.bth
            level_db.delete(key)
          end

          key = KEY_PREFIX[:height] + [utxo.block_height].pack('N').bth + out_point.to_payload.bth
          level_db.delete(key)
        end
      end

      def list_unspent(current_block_height: 9999999, min: 0, max: 9999999, addresses: nil)
        if addresses
          list_unspent_by_addresses(current_block_height, min: min, max: max, addresses: addresses)
        else
          list_unspent_by_block_height(current_block_height, min: min, max: max)
        end
      end

      def get_balance(account, current_block_height: 9999999, min: 0, max: 9999999)
        list_unspent_in_account(account, current_block_height, min: min, max: max).sum { |u| u.value }
      end

      private

      def utxos_between(from, to)
        level_db.each(from: from, to: to).map { |k, v| Bitcoin::Wallet::Utxo.parse_from_payload(v.htb) }
      end

      class ::Array
        def with_height(min, max)
          select { |u| u.block_height >= min && u.block_height <= max }
        end
      end

      def list_unspent_by_block_height(current_block_height, min: 0, max: 9999999)
        max_height = [current_block_height - min, 0].max
        min_height = [current_block_height - max, 0].max

        from = KEY_PREFIX[:height] + [min_height].pack('N').bth + '000000000000000000000000000000000000000000000000000000000000000000000000'
        to = KEY_PREFIX[:height] + [max_height].pack('N').bth + 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'
        utxos_between(from, to)
      end

      def list_unspent_by_addresses(current_block_height, min: 0, max: 9999999, addresses: [])
        script_pubkeys = addresses.map { |a| Bitcoin::Script.parse_from_addr(a).to_payload.bth }
        list_unspent_by_script_pubkeys(current_block_height, min: min, max: max, script_pubkeys: script_pubkeys)
      end

      def list_unspent_by_script_pubkeys(current_block_height, min: 0, max: 9999999, script_pubkeys: [])
        max_height = current_block_height - min
        min_height = current_block_height - max
        script_pubkeys.map do |key|
          from = KEY_PREFIX[:script] + key + '000000000000000000000000000000000000000000000000000000000000000000000000'
          to = KEY_PREFIX[:script] + key + 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'
          utxos_between(from, to).with_height(min_height, max_height)
        end.flatten
      end

      def list_unspent_in_account(account, current_block_height, min: 0, max: 9999999)
        return [] unless account
        script_pubkeys = account.watch_targets.map { |t| Bitcoin::Script.to_p2wpkh(t).to_payload.bth }
        list_unspent_by_script_pubkeys(current_block_height, min: min, max: max, script_pubkeys: script_pubkeys)
      end
    end
  end
end
