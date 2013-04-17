module Tire
  module Search
    class Query
      def span_near(options = {}, &block)
        @value = SpanNearQuery.new(options, &block).to_hash
      end
    end

    class SpanNearQuery
      def initialize(options = {}, &block)
        query_options = {:slop => 10, :in_order => false}.merge(options)
        
        @terms = []
        
        block.arity < 1 ? instance_eval(&block) : block.call(self) if block_given?

        @value = {:span_near => query_options.merge({:clauses => @terms})}
      end

      def term(name, value)
        @terms << {:span_term => {name => value}}
      end

      def to_hash
        @value
      end
    end
  end
end
