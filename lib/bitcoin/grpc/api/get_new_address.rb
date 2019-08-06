# frozen_string_literal: true

module Bitcoin
  module Grpc
    module Api
      class GetNewAddress
        attr_reader :spv

        def initialize(spv)
          @spv = spv
        end

        def execute(request)
          address = spv.wallet.generate_new_address(request.account_name)
          script = Bitcoin::Script.parse_from_addr(address)
          script_pubkey = script.to_payload.bth
          pubkey_hash = script.witness_data[1].bth
          spv.filter_add(pubkey_hash)
          Bitcoin::Grpc::GetNewAddressResponse.new(address: address, script_pubkey: script_pubkey)
        end
      end
    end
  end
end
