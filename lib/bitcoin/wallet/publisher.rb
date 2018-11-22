# frozen_string_literal: true

module Bitcoin
  module Wallet
    class Publisher < Concurrent::Actor::RestartingContext
      attr_reader :receivers

      def initialize
        @receivers = {}
      end

      def on_message(message)
        match message, (on Array.(:subscribe, ~any) do |type|
          if envelope.sender.is_a? Concurrent::Actor::Reference
            receivers[type.name] ||= []
            receivers[type.name] << envelope.sender
          end
        end), (on :unsubscribe do
          receivers.each { |receiver| receiver.delete(envelope.sender) }
        end), (on Array.(:subscribe?, ~any) do |type|
          receivers[type.name]&.include?(envelope.sender)
        end), (on any do
          receivers[message&.type&.name]&.each { |r| r << message }
        end)
      end
    end
  end
end
