RSpec.describe Bitcoin::Wallet::AssetHandler do
  describe '#on_message' do
    subject do
      asset_handler << message
      asset_handler.ask(:await).wait
    end

    let(:asset_handler) { described_class.spawn(:asset, spv, publisher) }
    let(:spv) { create_test_spv }
    let(:publisher) { Bitcoin::Wallet::Publisher.spawn(:publisher) }
    let(:wallet) { Bitcoin::Wallet::Base.create(1, 'tmp/wallet_db/').tap { |w| w.create_account('hoge') } }
    let(:db) { wallet.utxo_db }
    let(:tx_payload) do
      '0200000001427f57d9fb12521da329adbda27af5c03e03810ad476066a7e653a011fdbced7000000004847304402205ad2d520e37ce7a278029042bbad7c25d26addec6978a1db4e233dcb6603891f022013601c5211b836a77b02c630e17fa211e9ab1cc39b1cc003721c41b7a967a84201feffffff030000000000000000266a244f4101000364007b1b753d68747470733a2f2f6370722e736d2f35596753553150672d7100e1f5050000000016001445fcf49e1a60e8ea9ef774a0bc0839aaecf15fdd242d5a030000000016001425a2bbd8b5e1d90d061b5adbb3db283c39ebc8ab5a130000'
    end
    let(:tx) { Bitcoin::Tx.parse_from_payload(tx_payload.htb) }
    let(:block_height) { 9_999_999 }
    let(:script_pubkey) { Bitcoin::Script.to_p2wpkh('0a3355ef2085b1eb937c9e7729a0edde2d1e129e').to_payload.bth }
    let(:index) { 1 }
    let(:utxo) { Bitcoin::Grpc::Utxo.new(tx_hash: 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', index: index, block_height: block_height, value: 4, script_pubkey: script_pubkey) }

    before do
      allow(spv).to receive(:wallet).and_return(wallet)
      asset_handler
      publisher.ask(:await).wait
    end

    after do
      db.close
      wallet.close
      FileUtils.rm_r('tmp/wallet_db/')
    end

    context 'with Bitcoin::Grpc::EventUtxoSpent' do
      let(:message) { Bitcoin::Grpc::EventUtxoSpent.new(tx_hash: tx.tx_hash, tx_payload: tx_payload, out_point: out_point) }
      let(:out_point) { Bitcoin::Grpc::OutPoint.new(tx_hash: 'ff' * 32,  index: index) }

      it do
        expect(db).to receive(:delete_token)
        subject
      end
    end

    context 'with Bitcoin::Grpc::WatchAssetIdAssignedRequest' do
      let(:message) { Bitcoin::Grpc::WatchAssetIdAssignedRequest.new(tx_hash: tx.tx_hash, tx_payload: tx_payload) }

      context 'when transaction is issue transaction' do
        before do
          allow(Bitcoin::Grpc::OapService).to receive(:outputs_with_open_asset_id).and_return([{'asset_id' => 'oSqzjKUyr2ux62BuP2vzNm11t1RFGt2jr2', 'asset_quantity' => 1, 'oa_output_type' => 'issuance', 'n' => 0}, { 'oa_output_type' => 'nulldata', 'n' => 1 }])
          out_point = Bitcoin::OutPoint.new('114c88c1be09136dde076d3fad7069672692cf4340485ccbb273d7b37b0cd791', 0)
          db.save_utxo(out_point, 3, script_pubkey, 1)
        end

        it do
          expect(publisher).to receive(:<<).with(Bitcoin::Grpc::EventTokenIssued)
          subject
          publisher.ask(:await).wait
        end
      end

      context 'when transaction is transfer transaction' do
        before do
          allow(Bitcoin::Grpc::OapService).to receive(:outputs_with_open_asset_id).and_return([{ 'oa_output_type' => 'nulldata' , 'n' => 0}, {'asset_id' => 'oSqzjKUyr2ux62BuP2vzNm11t1RFGt2jr2', 'asset_quantity' => 1, 'oa_output_type' => 'transfer', 'n' => 1}])
          out_point = Bitcoin::OutPoint.new('114c88c1be09136dde076d3fad7069672692cf4340485ccbb273d7b37b0cd791', 1)
          db.save_utxo(out_point, 3, script_pubkey, 1)
        end

        it do
          expect(publisher).to receive(:<<).with(Bitcoin::Grpc::EventTokenTransfered)
          subject
          publisher.ask(:await).wait
        end
      end
    end
  end
end
