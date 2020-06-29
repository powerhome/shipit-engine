# frozen_string_literal: true

module Shipit
  module ProvisioningHandler
    NoRegisteredHandlerError = Class.new(StandardError)

    class << self
      def registry
        @registry ||= reset_registry!
      end

      def reset_registry!
        @registry = {}
      end

      def register(handler_class)
        registry[handler_class.to_s] = handler_class if handler_class.present?
      end

      def fetch(name)
        registry.fetch(name) do
          if name.present?
            raise(
              NoRegisteredHandlerError,
              "Failed to find a provisioning handler named '#{name}' in the ProvisioningHandler registry." \
              "Have you registered it via Provisioning::Handler.register?"
            )
          end

          default
        end
      end

      def default=(handler_class)
        registry[:default] = handler_class if handler_class.present?
      end

      def default
        registry.fetch(:default) { ProvisioningHandler::Base }
      end
    end
  end
end
