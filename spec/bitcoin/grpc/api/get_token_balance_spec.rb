
RSpec.describe Bitcoin::Grpc::Api::GetTokenBalance do
  describe '#execute' do
    subject { described_class.new(spv).execute(request) }

    let(:request) { Bitcoin::Grpc::GetTokenBalanceRequest.new(account_name: account_name, asset_type: asset_type1, asset_id: asset_id1) }
    let(:spv) { create_test_spv }
    let(:account_name) { 'test' }
    let(:wallet) { Bitcoin::Wallet::Base.create(1, 'tmp/wallet_db/').tap { |w| w.create_account('test') } }
    let(:db) { wallet.utxo_db }
    let(:account) { wallet.accounts.select { |a| a.name == account_name }.first }

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

    before do
      allow(spv).to receive(:wallet).and_return(wallet)
      utxo1 = db.save_utxo(out_point1, 3, script_pubkey1, 1)
      utxo2 = db.save_utxo(out_point2, 6, script_pubkey2, 4)
      utxo3 = db.save_utxo(out_point3, 9, script_pubkey3, 7)
      utxo4 = db.save_utxo(out_point4, 12, script_pubkey4, 10)
      db.save_token(asset_type1, asset_id1, 2, utxo1)
      db.save_token(asset_type1, asset_id1, 5, utxo2)
      db.save_token(asset_type1, asset_id1, 8, utxo3)
      db.save_token(asset_type2, asset_id1, 11, utxo4)
    end

    after do
      db.close
      wallet.close
      FileUtils.rm_r('tmp/wallet_db/')
    end

    it { expect(subject.balance).to eq 9 }
    it { expect(subject.token_balance).to eq 7 }
  end
end
