# frozen_string_literal: true

module Bitcoin
  module Grpc
    module Api
      class ListUnspent
        attr_reader :spv

        def initialize(spv)
          @spv = spv
        end

        def execute(request)
          height = spv.chain.latest_block.height
          utxos = spv.wallet.list_unspent(
            account_name: request.account_name,
            current_block_height: height,
            min: request.min,
            max: request.max,
            addresses: request.addresses
          )
          Bitcoin::Grpc::ListUnspentResponse.new(utxos: utxos)
        end
      end
    end
  end
end
