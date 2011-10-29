module Tire
  module Search

    class Query
      def initialize(&block)
        @value = {}
        block.arity < 1 ? self.instance_eval(&block) : block.call(self) if block_given?
      end

      def term(field, value)
        @value = { :term => { field => value } }
      end

      def terms(field, value, options={})
        @value = { :terms => { field => value } }
        @value[:terms].update( { :minimum_match => options[:minimum_match] } ) if options[:minimum_match]
        @value
      end

      def range(field, value)
        @value = { :range => { field => value } }
      end

      def string(value, options={})
        @value = { :query_string => { :query => value } }
        @value[:query_string].update(options)
        # TODO: https://github.com/elasticsearch/elasticsearch/wiki/Query-String-Query
        @value
      end

      def custom_score(options={}, &block)
        @custom_score ||= Query.new(&block)
        @value[:custom_score] = options
        @value[:custom_score].update({:query => @custom_score.to_hash})
        @value
      end

      def boolean(options={}, &block)
        @boolean ||= BooleanQuery.new(options)
        block.arity < 1 ? @boolean.instance_eval(&block) : block.call(@boolean) if block_given?
        @value[:bool] = @boolean.to_hash
        @value
      end

      def filtered(&block)
        @filtered = FilteredQuery.new
        block.arity < 1 ? @filtered.instance_eval(&block) : block.call(@filtered) if block_given?
        @value[:filtered] = @filtered.to_hash
        @value
      end

      def all
        @value = { :match_all => {} }
        @value
      end

      def ids(values, type)
        @value = { :ids => { :values => values, :type => type }  }
      end

      def to_hash
        @value
      end

      def to_json
        to_hash.to_json
      end

    end

    class BooleanQuery

      # TODO: Try to get rid of multiple `should`, `must`, etc invocations, and wrap queries directly:
      #
      #       boolean do
      #         should do
      #           string 'foo'
      #           string 'bar'
      #         end
      #       end
      #
      # Inherit from Query, implement `encode` method there, and overload it here, so it puts
      # queries in an Array instead of hash.

      def initialize(options={}, &block)
        @options = options
        @value   = {}
        block.arity < 1 ? self.instance_eval(&block) : block.call(self) if block_given?
      end

      def must(&block)
        (@value[:must] ||= []) << Query.new(&block).to_hash
        @value
      end

      def must_not(&block)
        (@value[:must_not] ||= []) << Query.new(&block).to_hash
        @value
      end

      def should(&block)
        (@value[:should] ||= []) << Query.new(&block).to_hash
        @value
      end

      def to_hash
        @value.update(@options)
      end
    end


    class FilteredQuery
      def initialize(&block)
        @value = {}
        block.arity < 1 ? self.instance_eval(&block) : block.call(self) if block_given?
      end

      def query(options={}, &block)
        @value[:query] = Query.new(&block).to_hash
        @value
      end

      def filter(type, *options)
        @value[:filter] ||= []
        @value[:filter] << Filter.new(type, *options).to_hash
        @value
      end

      def to_hash
        @value
      end

      def to_json
        to_hash.to_json
      end
    end

  end
end
