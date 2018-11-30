module Bitcoin
  module Wallet
    module AssetFeature
      module AssetType
        OPEN_ASSETS = 1
      end

      KEY_PREFIX = {
        asset_out_point: 'ao', # key: asset_type and out_point, value AssetOutput
        asset_script_pubkey: 'as',     # key: asset_type, script_pubkey and out_point, value AssetOutput
        asset_height: 'ah',    # key: asset_type, block_height and out_point, value AssetOutput
      }

      def save_token(asset_type, asset_id, asset_quantity, utxo)
        level_db.batch do
          asset_output = Bitcoin::Grpc::AssetOutput.new(
            asset_type: [asset_type].pack('C'),
            asset_id: asset_id,
            asset_quantity: asset_quantity,
            tx_hash: utxo.tx_hash,
            index: utxo.index,
            block_height: utxo.block_height
          )
          out_point = Bitcoin::OutPoint.new(utxo.tx_hash, utxo.index)
          payload = asset_output.to_proto.bth

          # out_point
          key = KEY_PREFIX[:asset_out_point] + [asset_type].pack('C').bth + out_point.to_payload.bth
          return if level_db.contains?(key)
          level_db.put(key, payload)

          # script_pubkey
          if utxo.script_pubkey
            key = KEY_PREFIX[:asset_script_pubkey] + [asset_type].pack('C').bth + utxo.script_pubkey + out_point.to_payload.bth
            level_db.put(key, payload)
          end

          # block_height
          key = KEY_PREFIX[:asset_height] + [asset_type].pack('C').bth + [utxo.block_height].pack('N').bth + out_point.to_payload.bth
          level_db.put(key, payload)
          utxo
        end
      end

      def delete_token(asset_type, utxo)
        level_db.batch do
          out_point = Bitcoin::OutPoint.new(utxo.tx_hash, utxo.index)

          key = KEY_PREFIX[:asset_out_point] + [asset_type].pack('C').bth + out_point.to_payload.bth
          return unless level_db.contains?(key)
          asset = Bitcoin::Grpc::AssetOutput.decode(level_db.get(key).htb)
          level_db.delete(key)


          if utxo.script_pubkey
            key = KEY_PREFIX[:asset_script_pubkey] + [asset_type].pack('C').bth + utxo.script_pubkey + out_point.to_payload.bth
            level_db.delete(key)
          end

          key = KEY_PREFIX[:asset_height] + [asset_type].pack('C').bth + [utxo.block_height].pack('N').bth + out_point.to_payload.bth
          level_db.delete(key)
          return asset
        end
      end

      def list_unspent_assets(asset_type, asset_id, current_block_height: 9999999, min: 0, max: 9999999, addresses: nil)
        raise NotImplementedError.new("asset_type should not be nil.") unless asset_type
        raise ArgumentError.new('asset_id should not be nil') unless asset_id

        if addresses
          list_unspent_assets_by_addresses(asset_type, asset_id, current_block_height, min: min, max: max, addresses: addresses)
        else
          list_unspent_assets_by_block_height(asset_type, asset_id, current_block_height, min: min, max: max)
        end
      end

      def get_asset_balance(asset_type, asset_id, account, current_block_height: 9999999, min: 0, max: 9999999, addresses: nil)
        raise NotImplementedError.new("asset_type should not be nil.") unless asset_type
        raise ArgumentError.new('asset_id should not be nil') unless asset_id

        list_unspent_assets_in_account(asset_type, asset_id, account, current_block_height, min: min, max: max).sum { |u| u.asset_quantity }
      end

      private

      def assets_between(from, to, asset_id)
        level_db.each(from: from, to: to)
          .map { |k, v| Bitcoin::Grpc::AssetOutput.decode(v.htb) }
          .select {|asset| asset.asset_id == asset_id }
      end

      def list_unspent_assets_by_block_height(asset_type, asset_id, current_block_height, min: 0, max: 9999999)
        max_height = [current_block_height - min, 0].max
        min_height = [current_block_height - max, 0].max

        from = KEY_PREFIX[:asset_height] + [asset_type, min_height].pack('CN').bth + '000000000000000000000000000000000000000000000000000000000000000000000000'
        to = KEY_PREFIX[:asset_height] + [asset_type, max_height].pack('CN').bth + 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'
        assets_between(from, to, asset_id)
      end

      def list_unspent_assets_by_addresses(asset_type, asset_id, current_block_height, min: 0, max: 9999999, addresses: [])
        script_pubkeys = addresses.map { |a| Bitcoin::Script.parse_from_addr(a).to_payload.bth }
        list_unspent_assets_by_script_pubkeys(asset_type, asset_id, current_block_height, min: min, max: max, script_pubkeys: script_pubkeys)
      end

      def list_unspent_assets_by_script_pubkeys(asset_type, asset_id, current_block_height, min: 0, max: 9999999, script_pubkeys: [])
        max_height = current_block_height - min
        min_height = current_block_height - max
        script_pubkeys.map do |key|
          from = KEY_PREFIX[:asset_script_pubkey] + [asset_type].pack('C').bth + key + '000000000000000000000000000000000000000000000000000000000000000000000000'
          to = KEY_PREFIX[:asset_script_pubkey] + [asset_type].pack('C').bth + key + 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'
          assets_between(from, to, asset_id).with_height(min_height, max_height)
        end.flatten
      end

      def list_unspent_assets_in_account(asset_type, asset_id, account, current_block_height, min: 0 , max: 9999999)
        return [] unless account
        script_pubkeys = account.watch_targets.map { |t| Bitcoin::Script.to_p2wpkh(t).to_payload.bth }
        list_unspent_assets_by_script_pubkeys(asset_type, asset_id, current_block_height, min: min, max: max, script_pubkeys: script_pubkeys)
      end
    end
  end
end
