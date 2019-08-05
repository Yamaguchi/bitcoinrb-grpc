
module Bitcoin
  module Grpc
    module Api
      autoload :ListUnspent, 'bitcoin/grpc/api/list_unspent'
      autoload :ListColoredUnspent, 'bitcoin/grpc/api/list_colored_unspent'
      autoload :ListUncoloredUnspent, 'bitcoin/grpc/api/list_uncolored_unspent'
      autoload :GetBalance, 'bitcoin/grpc/api/get_balance'
    end
  end
end
