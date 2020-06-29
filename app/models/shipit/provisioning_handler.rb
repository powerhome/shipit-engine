# frozen_string_literal: true

module Shipit
  module ProvisioningHandler
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
            Rails.logger.debug(
              "Failed to find a provisining handler named '#{name}' in the ProvisioningHandler registry." \
              "Have you registered it via Provisioning::Handler.register?" \
              "Using the default provisioner '#{default}'."
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
