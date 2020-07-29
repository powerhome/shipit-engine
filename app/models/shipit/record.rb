# frozen_string_literal: true
module Shipit
  class Record < ActiveRecord::Base
    self.abstract_class = true

    class << self
      def serializer_class
        @serializer_class ||= "#{name}Serializer".constantize
      end
    end

    delegate :serializer_class, to: :class
  end
end
