module Bitcoin
  module Wallet
    class Base
      attr_reader :utxo_db

      def get_balance(account_name)
        account = find_account(account_name)
        return 0 unless account
        utxo_db.get_balance(account)
      end

      def list_unspent(account_name: nil, current_block_height: 9999999, min: 0, max: 9999999, addresses: nil)
        if account_name
          account = find_account(account_name)
          return [] unless account
          utxo_db.list_unspent_in_account(account, current_block_height: current_block_height, min: min, max: max)
        else
          utxo_db.list_unspent(current_block_height: current_block_height, min: min, max: max, addresses: addresses)
        end
      end

      def list_uncolored_unspent(account_name: nil, current_block_height: 9999999, min: 0, max: 9999999)
        account = find_account(account_name)
        return [] unless account
        utxo_db.list_uncolored_unspent_in_account(account, current_block_height: current_block_height, min: min, max: max)
      end

      def list_unspent_assets_in_account(asset_type, asset_id, account_name: nil, current_block_height: 9999999, min: 0, max: 9999999)
        account = find_account(account_name)
        return [] unless account
        utxo_db.list_unspent_assets_in_account(asset_type, asset_id, account, current_block_height: current_block_height, min: min, max: max)
      end

      private

      def initialize(wallet_id, path_prefix)
        @path = "#{path_prefix}wallet#{wallet_id}/"
        @db = Bitcoin::Wallet::DB.new(@path)
        @wallet_id = wallet_id
        @utxo_db = Bitcoin::Wallet::UtxoDB.new("#{path_prefix}utxo#{wallet_id}/")
      end
    end
  end
end
