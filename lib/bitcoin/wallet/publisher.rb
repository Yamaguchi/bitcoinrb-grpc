# frozen_string_literal: true

module Bitcoin
  module Wallet
    class Publisher < Concurrent::Actor::RestartingContext
      attr_reader :receivers

      def initialize
        @receivers = {}
      end

      def on_message(message)
        case message
        when :unsubscribe
          receivers.each { |receiver| receiver.delete(envelope.sender) }
        when Array
          if message[0] == :subscribe
            if envelope.sender.is_a? Concurrent::Actor::Reference
              receivers[message[1].name] ||= []
              receivers[message[1].name] << envelope.sender
            end
          elsif message[0] == :subscribe?
            receivers[message[1].name]&.include?(envelope.sender)
          else
          end
        else
          receivers[message&.name]&.each { |r| r << message }
        end
      end
    end
  end
end
