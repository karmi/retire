module Slingshot
  module Search

    class Sort
      def initialize
        @value = []
        self.instance_eval(&Proc.new) if block_given?
      end

      def method_missing(id, arg = nil, *rest, &block)
        @value << (arg && { id => arg } || id)
        self
      end

      def to_json
        @value.to_json
      end
    end

  end
end
