# Generated by the protocol buffer compiler.  DO NOT EDIT!
# Source: bitcoin/grpc/grpc.proto for package 'bitcoin.grpc'

require 'grpc'
require 'bitcoin/grpc/grpc_pb'

module Bitcoin
  module Grpc
    module Blockchain
      class Service

        include GRPC::GenericService

        self.marshal_class_method = :encode
        self.unmarshal_class_method = :decode
        self.service_name = 'bitcoin.grpc.Blockchain'

        rpc :WatchTxConfirmed, WatchTxConfirmedRequest, stream(WatchTxConfirmedResponse)
        rpc :WatchUtxo, WatchUtxoRequest, stream(WatchUtxoResponse)
        rpc :WatchUtxoSpent, WatchUtxoSpentRequest, stream(WatchUtxoSpentResponse)
        rpc :WatchToken, WatchTokenRequest, stream(WatchTokenResponse)
        rpc :GetBlockchainInfo, GetBlockchainInfoRequest, GetBlockchainInfoResponse
        rpc :Events, stream(EventsRequest), stream(EventsResponse)
        rpc :ListUnspent, ListUnspentRequest, ListUnspentResponse
        rpc :ListColoredUnspent, ListColoredUnspentRequest, ListColoredUnspentResponse
        rpc :ListUncoloredUnspent, ListUncoloredUnspentRequest, ListUncoloredUnspentResponse
        rpc :GetBalance, GetBalanceRequest, GetBalanceResponse
        rpc :GetTokenBalance, GetTokenBalanceRequest, GetTokenBalanceResponse
        rpc :GetNewAddress, GetNewAddressRequest, GetNewAddressRequest
      end

      Stub = Service.rpc_stub_class
    end
  end
end
