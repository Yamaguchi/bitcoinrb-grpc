RSpec.describe Bitcoin::Wallet::AssetOutput do
  describe '#to_payload/.load' do
    let(:payload) { '010000000000000002ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000003000000040022414c6e33614b316653754732374e393655475942316b55595570474b526842754243' }
    it { expect(Bitcoin::Wallet::AssetOutput.parse_from_payload(payload.htb).to_payload.bth).to eq payload }
  end
end
