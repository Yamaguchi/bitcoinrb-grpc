# frozen_string_literal: true

module Bitcoin
  module Grpc
    module Api
      class GetBalance
        attr_reader :spv

        def initialize(spv)
          @spv = spv
        end

        def execute(request)
          height = spv.chain.latest_block.height
          balance = spv.wallet.get_balance(request.account_name)
          Bitcoin::Grpc::GetBalanceResponse.new(balance: balance)
        end
      end
    end
  end
end
