module Bitcoin
  module Wallet
    module Events
      class WatchTxConfirmed
        attr_reader :tx, :confirmations

        def initialize(tx, confirmations)
          @tx = tx
          @confirmations = confirmations
        end
      end

      class EventTxConfirmed
        attr_reader :tx, :confirmations

        def initialize(tx, confirmations)
          @tx = tx
          @confirmations = confirmations
        end
      end

      class EventUtxoRegistered
        attr_reader :tx, :utxo

        def initialize(tx, utxo)
          @tx = tx
          @utxo = utxo
        end
      end

      class EventUtxoSpent
        attr_reader :tx, :utxo

        def initialize(tx, utxo)
          @tx = tx
          @utxo = utxo
        end
      end

      class EventTokenRegistered
        attr_reader :asset_type, :asset_id, :asset_quantity

        def initialize(asset_type, asset_id, asset_quantity)
          @asset_type = asset_type
          @asset_id = asset_id
          @asset_quantity = asset_quantity
        end
      end

      class WatchAssetIdAssigned
        attr_reader :tx

        def initialize(tx)
          @tx = tx
        end
      end
    end
  end
end
