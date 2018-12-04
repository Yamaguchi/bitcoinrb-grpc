# frozen_string_literal: true

module Bitcoin
  module Wallet
    module Signer
      def self.sign(node, account_name, tx)
        account = find_account(node, account_name)
        return unless account

        tx.inputs.each.with_index do |input, index|
          spec = input_spec(node, account, tx, index)
          next unless spec
          sign_tx_for_p2wpkh(tx, index, spec[0], spec[1])
        end
        tx
      end

      private

      def self.input_spec(node, account, tx, index)
        input = tx.inputs[index]
        return unless input
        utxo = node.wallet.utxo_db.get_utxo(input.out_point)
        return unless utxo
        script_pubkey = utxo.script_pubkey
        keys = account.watch_targets
        key = nil
        (0..account.receive_depth + 1).reverse_each do |key_index|
          path = [account.path, 0, key_index].join('/')
          temp_key = node.wallet.master_key.derive(path).key
          if to_p2wpkh(temp_key).to_payload.bth == script_pubkey
            key = temp_key
            break
          end
        end
        unless key
          (0..account.change_depth + 1).reverse_each do |key_index|
            path = [account.path, 1, key_index].join('/')
            temp_key = node.wallet.master_key.derive(path).key
            if to_p2wpkh(temp_key).to_payload.bth == script_pubkey
              key = temp_key
              break
            end
          end
        end
        return unless key
        [key, utxo.value]
      end

      def self.find_account(node, account_name)
        node.wallet.accounts.find{|a| a.name == account_name}
      end

      def self.sign_tx_for_p2wpkh(tx, index, key, amount)
        sig = to_sighash(tx, index, key, amount)
        tx.inputs[index].script_witness = Bitcoin::ScriptWitness.new.tap do |witness|
          witness.stack << sig << key.pubkey.htb
        end
      end

      def self.to_sighash(tx, index, key, amount)
        sighash = tx.sighash_for_input(index, to_p2wpkh(key), amount: amount, sig_version: :witness_v0)
        key.sign(sighash) + [Bitcoin::SIGHASH_TYPE[:all]].pack('C')
      end

      def self.to_p2wpkh(key)
        Bitcoin::Script.to_p2wpkh(Bitcoin.hash160(key.pubkey))
      end
    end
  end
end
