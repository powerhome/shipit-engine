module Shipit
  module Webhooks
    class << self
      attr_accessor :extra_handlers

      extra_handlers = []

      def self.register_handler(&block)
        extra_handlers << block
      end
    end
  end
end
