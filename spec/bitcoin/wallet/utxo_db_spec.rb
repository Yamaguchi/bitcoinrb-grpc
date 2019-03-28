RSpec.describe Bitcoin::Wallet::UtxoDB do
  let(:wallet) { Bitcoin::Wallet::Base.create(1, 'tmp/wallet_db/').tap { |w| w.create_account('hoge') } }
  let(:db) { wallet.utxo_db }
  let(:account) { wallet.accounts.first }

  after do
    db.close
    wallet.close
    FileUtils.rm_r('tmp/wallet_db/')
  end

<<<<<<< HEAD
  describe 'get_tx' do
    subject { db.get_tx(tx.tx_hash) }

    before do
      db.save_tx(tx.tx_hash, tx_payload)
      db.save_tx_position(tx.tx_hash, 100, 2)
    end

    let(:tx_payload) do
      '0200000001a4c651f8a8a90e54988dad4a1be2e9e0aa35abf407e5c2d301b072' \
      '949dd720fd0000000049483045022100ac5545607a4b98950db8038256c48634' \
      'd85058c34b59caa55fca7f5a1f563ddf02206735fe476f94c8de29aa75b4b5f0' \
      'd06dc3e7ae94a0c8532fb139a8f24a7a3ecd01feffffff0200e1f50500000000' \
      '16001445fcf49e1a60e8ea9ef774a0bc0839aaecf15fdd2a2d5a030000000016' \
      '00143c5870422a2e0cc73f634978712cf896a87884ed3a130000'
    end
    let(:tx) { Bitcoin::Tx.parse_from_payload(tx_payload.htb) }
    let(:block_height) { 100 }

    it { expect(subject).to eq [ 100, 2, tx_payload] }
  end

=======
>>>>>>> Add gRPC message 'WatchUtxoSpent'
  describe 'save_utxo' do
    subject { db.save_utxo(out_point, 3, script_pubkey, 1) }

    let(:out_point) { Bitcoin::OutPoint.new('000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f', 0) }
    let(:script_pubkey) { Bitcoin::Script.to_p2wpkh('0a3355ef2085b1eb937c9e7729a0edde2d1e129e').to_payload.bth }

    it { expect { subject }.to change { db.level_db.keys.count }.by(3) }
    it { expect(subject).to be_kind_of Bitcoin::Grpc::Utxo }
  end

  describe 'delete_utxo' do
    subject { db.delete_utxo(out_point) }

    before { db.save_utxo(out_point, 3, script_pubkey, 1) }

    let(:out_point) { Bitcoin::OutPoint.new('000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f', 0) }
    let(:script_pubkey) { Bitcoin::Script.to_p2wpkh('0a3355ef2085b1eb937c9e7729a0edde2d1e129e').to_payload.bth }

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
    let(:script_pubkey1) { Bitcoin::Script.to_p2wpkh('0a3355ef2085b1eb937c9e7729a0edde2d1e129e').to_payload.bth }
    let(:script_pubkey2) { Bitcoin::Script.to_p2wpkh('a402e0e309dfa1d9a168ceace52e2b1b8baf3da8').to_payload.bth }
    let(:script_pubkey3) { Bitcoin::Script.to_p2wpkh('a402e0e309dfa1d9a168ceace52e2b1b8baf3da8').to_payload.bth }

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
    before do
      db.save_utxo(out_point1, 3, script_pubkey1, 1)
      db.save_utxo(out_point2, 6, script_pubkey2, 4)
      db.save_utxo(out_point3, 9, script_pubkey3, 7)
    end

    let(:out_point1) { Bitcoin::OutPoint.new('000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f', 0) }
    let(:out_point2) { Bitcoin::OutPoint.new('000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f', 1) }
    let(:out_point3) { Bitcoin::OutPoint.new('f0e0d0c0b0a090807060504030201000f0e0d0c0b0a090807060504030201000', 0) }
    let(:script_pubkey1) { Bitcoin::Script.to_p2wpkh(account.create_receive.hash160).to_payload.bth }
    let(:script_pubkey2) { Bitcoin::Script.to_p2wpkh(account.create_receive.hash160).to_payload.bth }
    let(:script_pubkey3) { Bitcoin::Script.to_p2wpkh('a402e0e309dfa1d9a168ceace52e2b1b8baf3da8').to_payload.bth }

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
    let(:utxo) { Bitcoin::Grpc::Utxo.new(tx_hash: 'ff' * 32, index: 1, block_height: block_height, value: 4, script_pubkey: script_pubkey) }
    let(:block_height) { 1000 }
    let(:script_pubkey) { Bitcoin::Script.to_p2wpkh('0a3355ef2085b1eb937c9e7729a0edde2d1e129e').to_payload.bth }

    describe '#save_token' do
      subject { db.save_token(asset_type, asset_id, asset_quantity, utxo) }

      it { expect { subject }.to change { db.level_db.keys.count }.by(3) }
    end

    describe '#delete_token' do
      subject { db.delete_token(utxo) }

      before { db.save_token(asset_type, asset_id, asset_quantity, utxo) }

      it { expect { subject }.to change { db.level_db.keys.count }.by(-3) }
    end

    describe '#list_unspent_assets' do
      subject { db.list_unspent_assets(asset_type1, asset_id1) }

      before do
        utxo1 = db.save_utxo(out_point1, 3, script_pubkey1, 1)
        utxo2 = db.save_utxo(out_point2, 6, script_pubkey2, 4)
        utxo3 = db.save_utxo(out_point3, 9, script_pubkey3, 7)
        utxo4 = db.save_utxo(out_point4, 12, script_pubkey4, 10)
        db.save_token(asset_type1, asset_id1, 2, utxo1)
        db.save_token(asset_type1, asset_id1, 5, utxo2)
        db.save_token(asset_type1, asset_id2, 8, utxo3)
        db.save_token(asset_type2, asset_id1, 11, utxo4)
      end

      let(:asset_type1) { Bitcoin::Wallet::AssetFeature::AssetType::OPEN_ASSETS }
      let(:asset_type2) { 2 } # Unknown
      let(:asset_id1) { 'ALn3aK1fSuG27N96UGYB1kUYUpGKRhBuBC' }
      let(:asset_id2) { '11111111111111111111111111111111111' }
      let(:out_point1) { Bitcoin::OutPoint.new('000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f', 0) }
      let(:out_point2) { Bitcoin::OutPoint.new('000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f', 1) }
      let(:out_point3) { Bitcoin::OutPoint.new('f0e0d0c0b0a090807060504030201000f0e0d0c0b0a090807060504030201000', 0) }
      let(:out_point4) { Bitcoin::OutPoint.new('f0e0d0c0b0a090807060504030201000f0e0d0c0b0a090807060504030201000', 1) }
      let(:script_pubkey1) { Bitcoin::Script.to_p2wpkh(account.create_receive.hash160).to_payload.bth }
      let(:script_pubkey2) { Bitcoin::Script.to_p2wpkh(account.create_receive.hash160).to_payload.bth }
      let(:script_pubkey3) { Bitcoin::Script.to_p2wpkh('a402e0e309dfa1d9a168ceace52e2b1b8baf3da8').to_payload.bth }
      let(:script_pubkey4) { Bitcoin::Script.to_p2wpkh(account.create_receive.hash160).to_payload.bth }

      it { expect(subject.size).to eq 2 }
      it { expect(subject[0].asset_quantity).to eq 2 }
      it { expect(subject[1].asset_quantity).to eq 5 }
    end

    describe '#list_unspent_assets_in_account' do
      subject { db.list_unspent_assets_in_account(asset_type1, asset_id1, account) }

      before do
        utxo1 = db.save_utxo(out_point1, 3, script_pubkey1, 1)
        utxo2 = db.save_utxo(out_point2, 6, script_pubkey2, 4)
        utxo3 = db.save_utxo(out_point3, 9, script_pubkey3, 7)
        utxo4 = db.save_utxo(out_point4, 12, script_pubkey4, 10)
        db.save_token(asset_type1, asset_id1, 2, utxo1)
        db.save_token(asset_type1, asset_id1, 5, utxo2)
        db.save_token(asset_type1, asset_id1, 8, utxo3)
        db.save_token(asset_type2, asset_id1, 11, utxo4)
      end

      let(:asset_type1) { Bitcoin::Wallet::AssetFeature::AssetType::OPEN_ASSETS }
      let(:asset_type2) { 2 } # Unknown
      let(:asset_id1) { 'ALn3aK1fSuG27N96UGYB1kUYUpGKRhBuBC' }
      let(:out_point1) { Bitcoin::OutPoint.new('000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f', 0) }
      let(:out_point2) { Bitcoin::OutPoint.new('000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f', 1) }
      let(:out_point3) { Bitcoin::OutPoint.new('f0e0d0c0b0a090807060504030201000f0e0d0c0b0a090807060504030201000', 0) }
      let(:out_point4) { Bitcoin::OutPoint.new('f0e0d0c0b0a090807060504030201000f0e0d0c0b0a090807060504030201000', 1) }
      let(:script_pubkey1) { Bitcoin::Script.to_p2wpkh(account.create_receive.hash160).to_payload.bth }
      let(:script_pubkey2) { Bitcoin::Script.to_p2wpkh(account.create_receive.hash160).to_payload.bth }
      let(:script_pubkey3) { Bitcoin::Script.to_p2wpkh('a402e0e309dfa1d9a168ceace52e2b1b8baf3da8').to_payload.bth }
      let(:script_pubkey4) { Bitcoin::Script.to_p2wpkh(account.create_receive.hash160).to_payload.bth }

      it { expect(subject.size).to eq 2 }
      it { expect(subject[0].asset_quantity).to eq 2 }
      it { expect(subject[1].asset_quantity).to eq 5 }
    end


    describe '#get_asset_balance' do
      subject { db.get_asset_balance(asset_type1, asset_id1, account) }

      before do
        utxo1 = db.save_utxo(out_point1, 3, script_pubkey1, 1)
        utxo2 = db.save_utxo(out_point2, 6, script_pubkey2, 4)
        utxo3 = db.save_utxo(out_point3, 9, script_pubkey3, 7)
        utxo4 = db.save_utxo(out_point4, 12, script_pubkey4, 10)
        db.save_token(asset_type1, asset_id1, 2, utxo1)
        db.save_token(asset_type1, asset_id1, 5, utxo2)
        db.save_token(asset_type1, asset_id2, 8, utxo3)
        db.save_token(asset_type2, asset_id1, 11, utxo4)
      end

      let(:asset_type1) { Bitcoin::Wallet::AssetFeature::AssetType::OPEN_ASSETS }
      let(:asset_type2) { 2 } # Unknown
      let(:asset_id1) { 'ALn3aK1fSuG27N96UGYB1kUYUpGKRhBuBC' }
      let(:asset_id2) { '11111111111111111111111111111111111' }
      let(:out_point1) { Bitcoin::OutPoint.new('000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f', 0) }
      let(:out_point2) { Bitcoin::OutPoint.new('000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f', 1) }
      let(:out_point3) { Bitcoin::OutPoint.new('f0e0d0c0b0a090807060504030201000f0e0d0c0b0a090807060504030201000', 0) }
      let(:out_point4) { Bitcoin::OutPoint.new('f0e0d0c0b0a090807060504030201000f0e0d0c0b0a090807060504030201000', 1) }
      let(:script_pubkey1) { Bitcoin::Script.to_p2wpkh(account.create_receive.hash160).to_payload.bth }
      let(:script_pubkey2) { Bitcoin::Script.to_p2wpkh(account.create_receive.hash160).to_payload.bth }
      let(:script_pubkey3) { Bitcoin::Script.to_p2wpkh('a402e0e309dfa1d9a168ceace52e2b1b8baf3da8').to_payload.bth }
      let(:script_pubkey4) { Bitcoin::Script.to_p2wpkh(account.create_receive.hash160).to_payload.bth }

      it { expect(subject).to eq 7 }
    end

    describe '#list_uncolored_unspent_in_account' do
      subject { db.list_uncolored_unspent_in_account(account) }

      before do
        utxo1 = db.save_utxo(out_point1, 3, script_pubkey1, 1)
        utxo2 = db.save_utxo(out_point2, 6, script_pubkey2, 4)
        utxo3 = db.save_utxo(out_point3, 9, script_pubkey3, 7)
        utxo4 = db.save_utxo(out_point4, 12, script_pubkey4, 10)
        db.save_token(asset_type1, asset_id1, 2, utxo1)
        db.save_token(asset_type1, asset_id2, 8, utxo3)
        db.save_token(asset_type2, asset_id1, 11, utxo4)
      end

      let(:asset_type1) { Bitcoin::Wallet::AssetFeature::AssetType::OPEN_ASSETS }
      let(:asset_type2) { 2 } # Unknown
      let(:asset_id1) { 'ALn3aK1fSuG27N96UGYB1kUYUpGKRhBuBC' }
      let(:asset_id2) { '11111111111111111111111111111111111' }
      let(:out_point1) { Bitcoin::OutPoint.new('000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f', 0) }
      let(:out_point2) { Bitcoin::OutPoint.new('000102030405060708090a0b0c0d0e0f000102030405060708090a0b0c0d0e0f', 1) }
      let(:out_point3) { Bitcoin::OutPoint.new('f0e0d0c0b0a090807060504030201000f0e0d0c0b0a090807060504030201000', 0) }
      let(:out_point4) { Bitcoin::OutPoint.new('f0e0d0c0b0a090807060504030201000f0e0d0c0b0a090807060504030201000', 1) }
      let(:script_pubkey1) { Bitcoin::Script.to_p2wpkh(account.create_receive.hash160).to_payload.bth }
      let(:script_pubkey2) { Bitcoin::Script.to_p2wpkh(account.create_receive.hash160).to_payload.bth }
      let(:script_pubkey3) { Bitcoin::Script.to_p2wpkh('a402e0e309dfa1d9a168ceace52e2b1b8baf3da8').to_payload.bth }
      let(:script_pubkey4) { Bitcoin::Script.to_p2wpkh(account.create_receive.hash160).to_payload.bth }

      it { expect(subject.size).to eq 1 }
      it { expect(subject[0].value).to eq 6 }
    end
  end
end
