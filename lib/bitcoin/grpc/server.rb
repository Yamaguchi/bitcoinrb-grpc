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

      attr_reader :spv, :utxo_handler, :asset_handler, :publisher, :logger

      def initialize(spv)
        @spv = spv
        @publisher = Bitcoin::Wallet::Publisher.spawn(:publisher)
        @utxo_handler = Bitcoin::Wallet::UtxoHandler.spawn(:utxo_handler, spv, publisher)
        @asset_handler = Bitcoin::Wallet::AssetHandler.spawn(:asset_handler, spv, publisher)
        @logger = Bitcoin::Logger.create(:debug)
      end

      def watch_tx_confirmed(request, call)
        logger.info("watch_tx_confirmed: #{request}")
        utxo_handler << request
        channel = Concurrent::Channel.new(capacity: 100)
        Receiver.spawn(:receiver, channel, request, publisher, [Bitcoin::Grpc::EventTxConfirmed])
        logger.info("watch_tx_confirmed: end")
        ResponseEnum.new(request, channel, WatchTxConfirmedResponseBuilder).each
      rescue => e
        logger.info("watch_tx_confirmed: #{e.message}")
        logger.info("watch_tx_confirmed: #{e.backtrace}")
      end

      def watch_utxo(request, call)
        logger.info("watch_utxo: #{request}")
        utxo_handler << request
        channel = Concurrent::Channel.new(capacity: 100)
        Receiver.spawn(:receiver, channel, request, publisher, [Bitcoin::Grpc::EventUtxoRegistered, Bitcoin::Grpc::EventUtxoSpent])
        logger.info("watch_utxo: end")
        ResponseEnum.new(request, channel, WatchUtxoResponseBuilder).each
      rescue => e
        logger.info("watch_utxo: #{e.message}")
        logger.info("watch_utxo: #{e.backtrace}")
      end

      def watch_token(request, call)
        logger.info("watch_token: #{request}")
        utxo_handler << request
        channel = Concurrent::Channel.new(capacity: 100)
        Receiver.spawn(:receiver, channel, request, publisher, [Bitcoin::Grpc::EventTokenIssued, Bitcoin::Grpc::EventTokenTransfered])
        logger.info("watch_token: end")
        ResponseEnum.new(request, channel, WatchTokenResponseBuilder).each
      rescue => e
        logger.info("watch_token: #{e.message}")
        logger.info("watch_token: #{e.backtrace}")
      end
    end

    class WatchTxConfirmedResponseBuilder
      def self.build(id, event)
        case event
        when Bitcoin::Grpc::EventTxConfirmed
          Bitcoin::Grpc::WatchTxConfirmedResponse.new(confirmed: event)
        end
      end
    end

    class WatchUtxoResponseBuilder
      def self.build(id, event)
        case event
        when Bitcoin::Grpc::EventUtxoRegistered
          Bitcoin::Grpc::WatchUtxoResponse.new(id: id, registered: event)
        when Bitcoin::Grpc::EventUtxoSpent
          Bitcoin::Grpc::WatchUtxoResponse.new(id: id, spent: event)
        end
      end
    end

    class WatchTokenResponseBuilder
      def self.build(id, event)
        case event
        when Bitcoin::Grpc::EventTokenIssued
          Bitcoin::Grpc::WatchTokenResponse.new(id: id, issued: event)
        when Bitcoin::Grpc::EventTokenTransfered
          Bitcoin::Grpc::WatchTokenResponse.new(id: id, transfered: event)
        when Bitcoin::Grpc::EventTokenBurned
          Bitcoin::Grpc::WatchTokenResponse.new(id: id, burned: event)
        end
      end
    end

    class Receiver < Concurrent::Actor::Context
      include Concurrent::Concern::Logging

      attr_reader :channel, :request

      def initialize(channel, request, publisher, classes)
        @channel = channel
        @request = request
        classes.each {|c| publisher << [:subscribe, c] }
      end
      def on_message(message)
        log(::Logger::DEBUG, "Receiver#on_message:#{message}")
        if request.id == message.request_id
          log(::Logger::DEBUG, "Receiver#on_message:#{message}")
          channel << message
        end
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
          event = channel.take
          yield wrapper_classs.build(event.request_id, event)
        end
      end
    end
  end
end
