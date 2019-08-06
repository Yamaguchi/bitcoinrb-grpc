
RSpec.describe Bitcoin::Grpc::Api::GetNewAddress do
  describe '#execute' do
    subject { described_class.new(spv).execute(request) }

    let(:request) { Bitcoin::Grpc::GetNewAddressRequest.new(account_name: account_name) }
    let(:spv) { create_test_spv }
    let(:account_name) { 'test' }
    let(:wallet) { Bitcoin::Wallet::Base.create(1, 'tmp/wallet_db/').tap { |w| w.create_account('test') } }
    let(:account) { wallet.accounts.select { |a| a.name == account_name }.first }
    let(:script_pubkey) { Bitcoin::Script.to_p2wpkh(account.derived_receive_keys.last.hash160).to_payload.bth }

    before do
      allow(spv).to receive(:wallet).and_return(wallet)
      allow(spv).to receive(:filter_add).and_return(nil)
    end

    after do
      wallet.close
      FileUtils.rm_r('tmp/wallet_db/')
    end

    it { expect(subject.address).to eq Bitcoin::Script.parse_from_payload(script_pubkey.htb).addresses.first }
    it { expect(subject.script_pubkey).to eq script_pubkey }
  end
end
