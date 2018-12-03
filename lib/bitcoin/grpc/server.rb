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

      attr_reader :spv, :watcher, :publisher, :logger

      def initialize(spv)
        @spv = spv
        @publisher = Bitcoin::Wallet::Publisher.spawn(:publisher)
        @watcher = Bitcoin::Wallet::UtxoHandler.spawn(:watcher, spv, publisher)
        @logger = Bitcoin::Logger.create(:debug)
      end

      def watch_tx_confirmed(request, call)
        logger.info("watch_tx_confirmed: #{request}")
        watcher << request
        channel = Concurrent::Channel.new
        Receiver.spawn(:receiver, channel, publisher, [Bitcoin::Grpc::EventTxConfirmed])
        ResponseEnum.new(request, channel, WatchTxConfirmedResponseBuilder).each
      end

      def watch_utxo(request, call)
        logger.info("watch_utxo: #{request}")
        watcher << request
        channel = Concurrent::Channel.new
        Receiver.spawn(:receiver, channel, publisher, [Bitcoin::Grpc::EventUtxoRegistered, Bitcoin::Grpc::EventUtxoSpent])
        ResponseEnum.new(request, channel, WatchUtxoResponseBuilder).each
      end

      def watch_token(request, call)
        logger.info("watch_token: #{request}")
        watcher << request
        channel = Concurrent::Channel.new
        Receiver.spawn(:receiver, channel, publisher, [Bitcoin::Grpc::EventTokenIssued, Bitcoin::Grpc::EventTokenTransfered])
        ResponseEnum.new(request, channel, WatchTokenResponseBuilder).each
      end
    end

    class WatchTxConfirmedResponseBuilder
      def self.build(event)
        case event
        when Bitcoin::Grpc::EventTxConfirmed
          Bitcoin::Grpc::WatchTxConfirmedResponse.new(confirmed: event)
        end
      end
    end

    class WatchUtxoResponseBuilder
      def self.build(event)
        case event
        when Bitcoin::Grpc::EventUtxoRegistered
          Bitcoin::Grpc::WatchUtxoResponse.new(registered: event)
        when Bitcoin::Grpc::EventUtxoSpent
          Bitcoin::Grpc::WatchUtxoResponse.new(spent: event)
        end
      end
    end

    class WatchTokenResponseBuilder
      def self.build(event)
        case event
        when Bitcoin::Grpc::EventTokenIssued
          Bitcoin::Grpc::WatchTokenResponse.new(issued: event)
        when Bitcoin::Grpc::EventTokenTransfered
          Bitcoin::Grpc::WatchTokenResponse.new(transfered: event)
        when Bitcoin::Grpc::EventTokenBurned
          Bitcoin::Grpc::WatchTokenResponse.new(burned: event)
        end
      end
    end

    class Receiver < Concurrent::Actor::Context
      include Concurrent::Concern::Logging

      attr_reader :channel
      def initialize(channel, publisher, classes)
        @channel = channel
        classes.each {|c| publisher << [:subscribe, c] }
      end
      def on_message(message)
        log(::Logger::DEBUG, "Receiver#on_message:#{message}")
        channel << message
      end
    end

    class ResponseEnum
      attr_reader :req, :channel, :wrapper_classs, :logger

      def initialize(req, channel, wrapper_classs)
        @req = req
        @channel = channel
        @wrapper_classs = wrapper_classs
        @logger = Bitcoin::Logger.create(:debug)
      end

      def each
        logger.info("ResponseEnum#each")
        return enum_for(:each) unless block_given?
        loop do
          yield wrapper_classs.build(channel.take)
        end
      end
    end
  end
end
