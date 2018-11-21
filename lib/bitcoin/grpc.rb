require 'bitcoin'
require 'bitcoin/grpc/version'

require 'leveldb'

module Bitcoin
  module Grpc
    class Error < StandardError; end
    # Your code goes here...
  end
  module Wallet
    autoload :Utxo, 'bitcoin/wallet/utxo'
    autoload :UtxoDB, 'bitcoin/wallet/utxo_db'
  end
end
