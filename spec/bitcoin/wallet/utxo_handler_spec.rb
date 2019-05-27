RSpec.describe Bitcoin::Wallet::UtxoHandler do
  describe '#header' do
    subject { handler.update(:header, {hash: '00' * 32, height: 101}) }

    let(:handler) { described_class.new(spv, publisher) }
    let(:spv) { create_test_spv }
    let(:publisher) { Bitcoin::Wallet::Publisher.spawn(:publisher) }
    let(:wallet) { Bitcoin::Wallet::Base.create(1, 'tmp/wallet_db/').tap { |w| w.create_account('hoge') } }

    before do
      allow(spv).to receive(:wallet).and_return(wallet)
    end

    after do
      wallet.utxo_db.close
      wallet.close
      FileUtils.rm_r('tmp/wallet_db/')
    end

    it do
      expect(publisher).to receive(:<<).with(Bitcoin::Grpc::BlockCreated)
      subject
    end
  end
end
