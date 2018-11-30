module Bitcoin
  module Grpc
    class Server < Bitcoin::Grpc::Blockchain::Service
      def self.run(spv)
        addr = "0.0.0.0:8080"
        s = GRPC::RpcServer.new
        s.add_http2_port(addr, :this_port_is_insecure)
        s.handle(new(spv))
        s.run_till_terminated
      end

      attr_reader :spv, :watcher, :publisher

      def initialize(spv)
        @spv = spv
        @publisher = Bitcoin::Wallet::Publisher.spawn(:publisher)
        @watcher = Bitcoin::Wallet::UtxoHandler.spawn(:watcher, spv, publisher)
      end

      def watch_tx_confirmed(request, call)
        watcher << request
        channel = Concurrent::Channel.new
        Receiver.spawn(:receiver, channel, publisher, [Bitcoin::Grpc::EventTxConfirmed])
        ResponseEnum.new(request, channel, Bitcoin::Grpc::WatchTxConfirmedResponse).each
      end

      def watch_utxo(request, call)
        watcher << request
        channel = Concurrent::Channel.new
        Receiver.spawn(:receiver, channel, publisher, [Bitcoin::Grpc::EventUtxoRegistered, Bitcoin::Grpc::EventUtxoSpent])
        ResponseEnum.new(request, channel, Bitcoin::Grpc::WatchUtxoResponse).each
      end

      def watch_token(request, call)
        watcher << request
        channel = Concurrent::Channel.new
        Receiver.spawn(:receiver, channel, publisher, [Bitcoin::Grpc::EventTokenIssued, Bitcoin::Grpc::EventTokenTransfered])
        ResponseEnum.new(request, channel, Bitcoin::Grpc::WatchTokenResponse).each
      end
    end

    class Receiver < Concurrent::Actor::Context
      attr_reader :channels
      def initialize(channel, publisher, classes)
        @channel = channel
        classes.each {|c| publisher << [:subscribe, c] }
      end
      def on_message(message)
        channel << message
      end
    end

    class ResponseEnum
      attr_reader :req, :channel, :wrapper_classs

      def initialize(req, channel, wrapper_classs)
        @req = req
        @channel = channel
        @wrapper_classs = wrapper_classs
      end

      def each
        return enum_for(:each) unless block_given?
        loop do
          yield wrapper_classs.new(event: channel.take)
        end
      end
    end
  end
end
