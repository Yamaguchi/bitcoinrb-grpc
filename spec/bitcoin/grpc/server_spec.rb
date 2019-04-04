
RSpec.describe Bitcoin::Grpc::Server do
  describe '#events' do
    subject do
      described_class.new(spv, publisher, utxo_handler, asset_handler).events(requests)
    end

    let(:requests) { [Bitcoin::Grpc::EventsRequest.new(operation: :SUBSCRIBE, event_type: "Connect")] }
    let(:spv) { create_test_spv }
    let(:publisher) { Bitcoin::Wallet::Publisher.spawn(:publisher) }
    let(:utxo_handler) { Concurrent::Actor::Context.spawn(:utxo_handler) }
    let(:asset_handler) { Concurrent::Actor::Context.spawn(:asset_handler) }

    it do
      expect(publisher).to receive(:<<).with([:subscribe, Bitcoin::Grpc::Connect])
      subject
      publisher.ask(:await).wait
    end

    it do
      responses = subject
      connect = Bitcoin::Grpc::Connect.new(host: "localhost", port: 8333)
      publisher << connect
      response_event = responses.each do |response|
        break response.connect
      end
      expect(response_event).to eq connect
    end
  end
end
