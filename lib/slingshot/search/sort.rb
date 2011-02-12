module Slingshot
  module Search

    class Sort
      def initialize(&block)
        @value = []
        self.instance_eval(&block) if block_given?
      end

      def field(name, direction=nil)
        @value << ( direction ? { name => direction } : name )
        self
      end

      def method_missing(id, *args, &block)
        case arg = args.shift
          when String, Symbol, Hash then @value << { id => arg }
          else @value << id
        end
        self
      end

      def to_json
        @value.to_json
      end
    end

  end
end
