# frozen_string_literal: true

module Bitcoin
  module Grpc
    module Api
      class GetTokenBalance
        attr_reader :spv

        def initialize(spv)
          @spv = spv
        end

        def execute(request)
          height = spv.chain.latest_block.height
          assets = spv.wallet.list_unspent_assets_in_account(
            request.asset_type,
            request.asset_id,
            account_name: request.account_name,
            current_block_height: height,
            min: 0,
            max: 9999999
          )
          balance = assets.sum(&:value)
          token_balance = assets.sum(&:asset_quantity)

          Bitcoin::Grpc::GetTokenBalanceResponse.new(balance: balance, token_balance: token_balance)
        end
      end
    end
  end
end
