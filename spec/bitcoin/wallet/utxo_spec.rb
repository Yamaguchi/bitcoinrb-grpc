RSpec.describe Bitcoin::Wallet::Utxo do
  describe '#to_payload/.load' do
    let(:payload) { 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000010000000200000000000000041600140a3355ef2085b1eb937c9e7729a0edde2d1e129e' }
    it { expect(Bitcoin::Wallet::Utxo.parse_from_payload(payload.htb).to_payload.bth).to eq payload }
  end
end
