require 'bitcoin'
require 'bitcoin/grpc/version'

require 'concurrent'
require 'concurrent-edge'
require 'leveldb'

require 'extensions/string'

module Bitcoin
  module Grpc
    class Error < StandardError; end

    require 'bitcoin/grpc/grpc_pb'
    require 'bitcoin/grpc/grpc_services_pb'

    require 'extensions/bitcoin/rpc/request_handler'
    require 'extensions/bitcoin/wallet/base'
    require 'extensions/bitcoin/wallet/db'
    require 'extensions/bitcoin/tx'

    autoload :Api, 'bitcoin/grpc/api'
    autoload :OapService, 'bitcoin/grpc/oap_service'
    autoload :Server, 'bitcoin/grpc/server'
  end

  module Wallet
    autoload :AssetFeature, 'bitcoin/wallet/asset_feature'
    autoload :AssetHandler, 'bitcoin/wallet/asset_handler'
    autoload :Publisher, 'bitcoin/wallet/publisher'
    autoload :Signer, 'bitcoin/wallet/signer'
    autoload :UtxoDB, 'bitcoin/wallet/utxo_db'
    autoload :UtxoHandler, 'bitcoin/wallet/utxo_handler'
  end
end

# Concurrent.use_simple_logger Logger::DEBUG
