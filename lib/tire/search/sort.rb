module Tire
  module Search

    class Sort
      def initialize(&block)
        @value = []
        block.arity < 1 ? self.instance_eval(&block) : block.call(self) if block_given?
      end

      def by(name, direction=nil)
        @value << ( direction ? { name => direction } : name )
        self
      end

      def to_ary
        @value
      end

      def to_json(options={})
        @value.to_json
      end
    end

  end
end
