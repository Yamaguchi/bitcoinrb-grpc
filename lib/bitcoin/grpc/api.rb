
module Bitcoin
  module Grpc
    module Api
      autoload :ListUnspent, 'bitcoin/grpc/api/list_unspent'
      autoload :ListColoredUnspent, 'bitcoin/grpc/api/list_colored_unspent'
    end
  end
end
