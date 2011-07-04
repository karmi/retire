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

      def method_missing(id, *args, &block)
        Tire.warn "Using methods when sorting has been deprecated, please use the `by` method: " +
                  "sort { by :#{id}#{ args.empty? ? '' : ', ' + args.first.inspect } }"

        by id, args.shift
      end

      def to_ary
        @value
      end

      def to_json
        @value.to_json
      end
    end

  end
end
