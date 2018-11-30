require 'bitcoin'
require 'bitcoin/grpc/version'

require 'concurrent'
require 'concurrent-edge'
require 'leveldb'

module Bitcoin


  module Grpc
    class Error < StandardError; end

    require 'bitcoin/grpc/grpc_pb'
    require 'bitcoin/grpc/grpc_services_pb'

    autoload :Server, 'bitcoin/grpc/server'
  end

  module Wallet
    autoload :AssetFeature, 'bitcoin/wallet/asset_feature'
    autoload :AssetHandler, 'bitcoin/wallet/asset_handler'
    autoload :Publisher, 'bitcoin/wallet/publisher'
    autoload :UtxoDB, 'bitcoin/wallet/utxo_db'
    autoload :UtxoHandler, 'bitcoin/wallet/utxo_handler'
  end
end

Concurrent.use_simple_logger Logger::DEBUG
