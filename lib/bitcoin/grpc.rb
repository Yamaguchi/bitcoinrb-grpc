require 'bitcoin'
require 'bitcoin/grpc/version'

require 'concurrent'
require 'concurrent-edge'
require 'leveldb'

module Bitcoin
  module Grpc
    class Error < StandardError; end
  end

  module Wallet
    autoload :AssetFeature, 'bitcoin/wallet/asset_feature'
    autoload :AssetHandler, 'bitcoin/wallet/asset_handler'
    autoload :AssetOutput, 'bitcoin/wallet/asset_output'
    autoload :Events, 'bitcoin/wallet/events'
    autoload :Publisher, 'bitcoin/wallet/publisher'
    autoload :Utxo, 'bitcoin/wallet/utxo'
    autoload :UtxoDB, 'bitcoin/wallet/utxo_db'
    autoload :UtxoListener, 'bitcoin/wallet/utxo_handler'
  end
end

Concurrent.use_simple_logger Logger::DEBUG
