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

      def get_blockchain_info(request, call)
        best_block = spv.chain.latest_block
        GetBlockchainInfoResponse.new(
          chain: Bitcoin.chain_params.network.to_s,
          headers: best_block.height,
          bestblockhash: best_block.header.block_id,
          chainwork: best_block.header.work,
          mediantime: spv.chain.mtp(best_block.block_hash)
        )
      rescue => e
        logger.info("get_blockchain_info: #{e.message}")
        logger.info("get_blockchain_info: #{e.backtrace}")
      end

      def watch_tx_confirmed(request, call)
        logger.info("watch_tx_confirmed: #{request}")
        utxo_handler << request
        response = []
        Receiver.spawn(:receiver, request, response, publisher, [Bitcoin::Grpc::EventTxConfirmed])
        logger.info("watch_tx_confirmed: end")
        ResponseEnum.new(request, response, WatchTxConfirmedResponseBuilder).each
      rescue => e
        logger.info("watch_tx_confirmed: #{e.message}")
        logger.info("watch_tx_confirmed: #{e.backtrace}")
      end

      def watch_utxo(request, call)
        logger.info("watch_utxo: #{request}")
        utxo_handler << request
        response = []
        Receiver.spawn(:receiver, request, response, publisher, [Bitcoin::Grpc::EventUtxoRegistered, Bitcoin::Grpc::EventUtxoSpent])
        logger.info("watch_utxo: end")
        ResponseEnum.new(request, response, WatchUtxoResponseBuilder).each
      rescue => e
        logger.info("watch_utxo: #{e.message}")
        logger.info("watch_utxo: #{e.backtrace}")
      end

      def watch_utxo_spent(request, call)
        logger.info("watch_utxo_spent: #{request}")
        utxo_handler << request
        response = []
        Receiver.spawn(:receiver, request, response, publisher, [Bitcoin::Grpc::EventUtxoSpent])
        logger.info("watch_utxo_spent: end")
        ResponseEnum.new(request, response, WatchUtxoSpentResponseBuilder).each
      rescue => e
        logger.info("watch_utxo_spent: #{e.message}")
        logger.info("watch_utxo_spent: #{e.backtrace}")
      end

      def watch_token(request, call)
        logger.info("watch_token: #{request}")
        utxo_handler << request
        response = []
        Receiver.spawn(:receiver, request, response, publisher, [Bitcoin::Grpc::EventTokenIssued, Bitcoin::Grpc::EventTokenTransfered])
        logger.info("watch_token: end")
        ResponseEnum.new(request, response, WatchTokenResponseBuilder).each
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

    class WatchUtxoSpentResponseBuilder
      def self.build(id, event)
        case event
        when Bitcoin::Grpc::EventUtxoSpent
          Bitcoin::Grpc::WatchUtxoSpentResponse.new(id: id, spent: event)
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

      attr_reader :request, :response

      def initialize(request, response, publisher, classes)
        @request = request
        @response = response
        classes.each {|c| publisher << [:subscribe, c] }
      end
      def on_message(message)
        if request.id == message.request_id
          log(::Logger::DEBUG, "Receiver#on_message:#{message}")
          response << message
        end
      end
    end

    class ResponseEnum
      attr_reader :req, :response, :wrapper_classs, :logger

      def initialize(req, response, wrapper_classs)
        @req = req
        @response = response
        @wrapper_classs = wrapper_classs
        @logger = Bitcoin::Logger.create(:debug)
      end

      def each
        return enum_for(:each) unless block_given?
        loop do
          event = response.first
          if event
            yield wrapper_classs.build(event.request_id, event)
          else
            sleep(1)
          end
        end
      end
    end
  end
end
