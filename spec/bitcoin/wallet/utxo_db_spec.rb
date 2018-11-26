RSpec.describe Bitcoin::Wallet::UtxoDB do
  let(:db) { described_class.new('./tmp/db/tx') }

  after do
    db.close
    FileUtils.rm_r('tmp/db/tx')
  end

  describe 'save_utxo' do
    subject { db.save_utxo(out_point, 3, script_pubkey, 1) }

    let(:out_point) { Bitcoin::OutPoint.new('000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f', 0) }
    let(:script_pubkey) { Bitcoin::Script.to_p2wpkh('0a3355ef2085b1eb937c9e7729a0edde2d1e129e') }

    it { expect { subject }.to change { db.level_db.keys.count }.by(3) }
  end

  describe 'delete_utxo' do
    subject { db.delete_utxo(out_point) }

    before { db.save_utxo(out_point, 3, script_pubkey, 1) }

    let(:out_point) { Bitcoin::OutPoint.new('000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f', 0) }
    let(:script_pubkey) { Bitcoin::Script.to_p2wpkh('0a3355ef2085b1eb937c9e7729a0edde2d1e129e') }

    it { expect { subject }.to change { db.level_db.keys.count }.by(-3) }
  end

  describe 'list_unspent' do
    before do
      db.save_utxo(out_point1, 3, script_pubkey1, 1)
      db.save_utxo(out_point2, 6, script_pubkey2, 4)
      db.save_utxo(out_point3, 9, script_pubkey3, 7)
    end

    let(:out_point1) { Bitcoin::OutPoint.new('000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f', 0) }
    let(:out_point2) { Bitcoin::OutPoint.new('000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f', 1) }
    let(:out_point3) { Bitcoin::OutPoint.new('f0e0d0c0b0a090807060504030201000f0e0d0c0b0a090807060504030201000', 0) }
    let(:script_pubkey1) { Bitcoin::Script.to_p2wpkh('0a3355ef2085b1eb937c9e7729a0edde2d1e129e') }
    let(:script_pubkey2) { Bitcoin::Script.to_p2wpkh('a402e0e309dfa1d9a168ceace52e2b1b8baf3da8') }
    let(:script_pubkey3) { Bitcoin::Script.to_p2wpkh('a402e0e309dfa1d9a168ceace52e2b1b8baf3da8') }

    context 'list all' do
      subject { db.list_unspent }

      it { expect(subject.size).to eq 3 }
    end

    context 'when min specified' do
      subject { db.list_unspent(current_block_height: 10, min: 4) }

      it { expect(subject.size).to eq 2 }
    end

    context 'when max specified' do
      subject { db.list_unspent(current_block_height: 10, max: 5) }

      it { expect(subject.size).to eq 1 }
    end

    context 'when address specified' do
      subject { db.list_unspent(addresses: ['bc1q5spwpccfm7sangtge6kw2t3trw9670dgauh4xy']) }

      it { expect(subject.size).to eq 2 }
    end
  end

  describe 'get_balance' do
    let(:wallet) { Bitcoin::Wallet::Base.create(1, 'tmp/wallet_db/').tap { |w| w.create_account('hoge') } }
    let(:account) { wallet.accounts.first }

    before do
      db.save_utxo(out_point1, 3, script_pubkey1, 1)
      db.save_utxo(out_point2, 6, script_pubkey2, 4)
      db.save_utxo(out_point3, 9, script_pubkey3, 7)
    end

    after do
      wallet.close
      FileUtils.rm_r('tmp/wallet_db')
    end

    let(:out_point1) { Bitcoin::OutPoint.new('000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f', 0) }
    let(:out_point2) { Bitcoin::OutPoint.new('000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f', 1) }
    let(:out_point3) { Bitcoin::OutPoint.new('f0e0d0c0b0a090807060504030201000f0e0d0c0b0a090807060504030201000', 0) }
    let(:script_pubkey1) { Bitcoin::Script.to_p2wpkh(account.create_receive.hash160) }
    let(:script_pubkey2) { Bitcoin::Script.to_p2wpkh(account.create_receive.hash160) }
    let(:script_pubkey3) { Bitcoin::Script.to_p2wpkh('a402e0e309dfa1d9a168ceace52e2b1b8baf3da8') }

    context 'with all balance' do
      subject { db.get_balance(account) }

      it { expect(subject).to eq 9 }
    end

    context 'when min specified' do
      subject { db.get_balance(account, current_block_height: 10, min: 8) }

      it { expect(subject).to eq 3 }
    end

    context 'when max specified' do
      subject { db.get_balance(account, current_block_height: 10, max: 7) }

      it { expect(subject).to eq 6 }
    end

    xcontext 'many utxo' do
      subject { db.get_balance(account2) }

      let(:script_pubkey) { Bitcoin::Script.to_p2wpkh(account2.create_receive.hash160) }
      let(:account2) { wallet.accounts.last }

      before do
        1000.times do |i|
          out_point = Bitcoin::OutPoint.new('ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', i)
          db.save_utxo(out_point, 3, script_pubkey, 1, 2)
        end
      end

      # TODO : use rspec-benchmark(https://github.com/piotrmurach/rspec-benchmark)
      it { expect(subject).to eq 3000 }
    end
  end

  describe 'AssetFeature' do
    let(:asset_type) { Bitcoin::Wallet::AssetFeature::AssetType::OPEN_ASSETS }
    let(:asset_id) { 'ALn3aK1fSuG27N96UGYB1kUYUpGKRhBuBC' }
    let(:asset_quantity) { 1 }
    let(:utxo) { Bitcoin::Wallet::Utxo.new('ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', 1, 2, value: 4, script_pubkey: script_pubkey) }
    let(:block_height) { 1000 }
    let(:script_pubkey) { Bitcoin::Script.to_p2wpkh('0a3355ef2085b1eb937c9e7729a0edde2d1e129e') }

    describe '#save_token' do
      subject { db.save_token(asset_type, asset_id, asset_quantity, utxo) }

      it { expect { subject }.to change { db.level_db.keys.count }.by(3) }
    end

    describe '#delete_token' do
      subject { db.delete_token(asset_type, utxo) }

      before { db.save_token(asset_type, asset_id, asset_quantity, utxo) }

      it { expect { subject }.to change { db.level_db.keys.count }.by(-3) }
    end

    describe '#list_unspent_assets' do
      # list_unspent_assets(asset_type, asset_id, current_block_height: 9999999, min: 0, max: 9999999, addresses: nil)

    end

    describe '#get_asset_balance' do
      # get_asset_balance(asset_type, asset_id, account, current_block_height: 9999999, min: 0, max: 9999999, addresses: nil)

    end
  end

end
