# frozen_string_literal: true

module Bitcoin
  module Grpc
    module Api
      class ListColoredUnspent
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
            min: request.min,
            max: request.max
          )
          Bitcoin::Grpc::ListColoredUnspentResponse.new(assets: assets)
        end
      end
    end
  end
end
