# frozen_string_literal: true

module Bitcoin
  module Grpc
    module Api
      class ListUncoloredUnspent
        attr_reader :spv

        def initialize(spv)
          @spv = spv
        end

        def execute(request)
          height = spv.chain.latest_block.height
          utxos = spv.wallet.list_uncolored_unspent(
            account_name: request.account_name,
            current_block_height: height,
            min: request.min,
            max: request.max
          )
          Bitcoin::Grpc::ListUncoloredUnspentResponse.new(utxos: utxos)
        end
      end
    end
  end
end
