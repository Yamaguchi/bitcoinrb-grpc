
RSpec.describe Bitcoin::Grpc::Api::ListUnspent do
  describe '#execute' do
    subject { described_class.new(spv).execute(request) }

    let(:request) { Bitcoin::Grpc::ListUnspentRequest.new(account_name: account_name, min: 0, max: 999999) }
    let(:spv) { create_test_spv }
    let(:account_name) { 'test' }
    let(:wallet) { Bitcoin::Wallet::Base.create(1, 'tmp/wallet_db/').tap { |w| w.create_account('test') } }
    let(:db) { wallet.utxo_db }
    let(:account) { wallet.accounts.select { |a| a.name == account_name }.first }
    let(:script_pubkey1) { Bitcoin::Script.to_p2wpkh(account.create_receive.hash160).to_payload.bth }
    let(:script_pubkey2) { Bitcoin::Script.to_p2wpkh(account.create_receive.hash160).to_payload.bth }

    before do
      allow(spv).to receive(:wallet).and_return(wallet)
      out_point = Bitcoin::OutPoint.new('114c88c1be09136dde076d3fad7069672692cf4340485ccbb273d7b37b0cd791', 1)
      db.save_utxo(out_point, 3, script_pubkey1, 100)
      out_point2 = Bitcoin::OutPoint.new('114c88c1be09136dde076d3fad7069672692cf4340485ccbb273d7b37b0cd791', 2)
      db.save_utxo(out_point2, 5, script_pubkey2, 100)
    end

    after do
      db.close
      wallet.close
      FileUtils.rm_r('tmp/wallet_db/')
    end

    it { expect(subject.utxos.size).to eq 2 }
    it { expect(subject.utxos[0].value).to eq 3 }
  end
end
