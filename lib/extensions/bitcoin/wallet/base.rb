module Bitcoin
  module Wallet
    class Base
      attr_reader :utxo_db

      def get_balance(account_name)
        account = find_account(account_name)
        raise ArgumentError.new('Account does not exist.') unless account
        utxo_db.get_balance(account)
      end

      def list_unspent(current_block_height: 9999999, min: 0, max: 9999999, addresses: nil)
        utxo_db.list_unspent(current_block_height: current_block_height, min: min, max: max, addresses: addresses)
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
