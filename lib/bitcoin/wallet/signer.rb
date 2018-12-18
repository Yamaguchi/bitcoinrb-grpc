# frozen_string_literal: true

module Bitcoin
  module Wallet
    module Signer
      def self.sign(wallet, account_name, tx)
        account = find_account(wallet, account_name)
        return unless account

        tx.inputs.each.with_index do |input, index|
          spec = input_spec(wallet, account, tx, index)
          next unless spec
          sign_tx_for_p2wpkh(tx, index, spec[0], spec[1])
        end
        tx
      end

      private

      def self.input_spec(wallet, account, tx, index)
        input = tx.inputs[index]
        return unless input
        utxo = wallet.utxo_db.get_utxo(input.out_point)
        return unless utxo
        script_pubkey = utxo.script_pubkey
        _, _, key_purpose, key_index = wallet.db.get_key_index(script_pubkey)
        return unless key_index
        path = [account.path, key_purpose, key_index].join('/')
        key = wallet.master_key.derive(path).key
        return unless key
        [key, utxo.value]
      end

      def self.find_account(wallet, account_name)
        wallet.accounts.find{|a| a.name == account_name}
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
