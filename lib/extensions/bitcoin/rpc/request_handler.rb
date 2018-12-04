module Bitcoin
  module RPC
    module RequestHandler
      def listunspent(min = 0, max = 999999, addresses: nil)
        height = node.chain.latest_block.height
        utxos = node.wallet.list_unspent(current_block_height: height, min: min, max: max, addresses: addresses)
        utxos.map do |u|
          {
            tx_hash: u.tx_hash,
            index: u.index,
            value: u.value,
            script_pubkey: u.script_pubkey.to_payload.bth,
            confirmations: height - u.block_height
          }
        end
      end

      def getbalance(account_name)
        node.wallet.get_balance(account_name)
      end

      # create new bitcoin address for receiving payments.
      def getnewaddress(account_name)
        address = node.wallet.generate_new_address(account_name)
        script = Bitcoin::Script.parse_from_addr(address)
        pubkey_hash = script.witness_data[1].bth
        node.filter_add(pubkey_hash)
        address
      end

      def createaccount(account_name)
        account = node.wallet.create_account(Bitcoin::Wallet::Account::PURPOSE_TYPE[:native_segwit], account_name)
        account.to_h
      rescue
        {}
      end
    end
  end
end
