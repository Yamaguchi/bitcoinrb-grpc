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
    autoload :Utxo, 'bitcoin/wallet/utxo'
    autoload :UtxoDB, 'bitcoin/wallet/utxo_db'
    autoload :Listener, 'bitcoin/wallet/listener'
    autoload :Publisher, 'bitcoin/wallet/publisher'
  end
end

Concurrent.use_simple_logger Logger::DEBUG
