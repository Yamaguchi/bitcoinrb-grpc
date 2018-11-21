RSpec.describe Bitcoin::Wallet::Utxo do
  describe '#to_payload/.load' do
    let(:script_pubkey) { Bitcoin::Script.to_p2wpkh('0a3355ef2085b1eb937c9e7729a0edde2d1e129e') }
    let(:utxo) { Bitcoin::Wallet::Utxo.new('ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff', 1, 2, 3, value: 4, script_pubkey: script_pubkey) }
    let(:payload) { 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000001000000020000000300000000000000041600140a3355ef2085b1eb937c9e7729a0edde2d1e129e' }
    it { expect(Bitcoin::Wallet::Utxo.parse_from_payload(payload.htb).to_payload.bth).to eq payload }
  end
end
