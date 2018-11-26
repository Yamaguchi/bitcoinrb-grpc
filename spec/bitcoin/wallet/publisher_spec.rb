RSpec.describe Bitcoin::Wallet::Publisher do
  class Receiver < Concurrent::Actor::Context
    def initialize(broadcast)
      broadcast << [:subscribe, Bitcoin::Wallet::Events::EventTxConfirmed]
    end

    def on_message(message)
    end
  end

  let(:receiver) { Receiver.spawn(:receiver, publisher) }
  let(:publisher) { described_class.spawn(:publisher) }
  let(:message) { Bitcoin::Wallet::Events::EventTxConfirmed.new(tx, 1) }
  let(:tx) { Bitcoin::Tx.new }

  describe 'on_message' do
    subject do
      publisher.ask(:await).wait
      publisher << message
      publisher.ask(:await).wait
      receiver.ask(:await).wait
    end

    it do
      expect(receiver).to receive(:<<).with(message)
      subject
    end
  end
end
