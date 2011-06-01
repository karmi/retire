module Tire
  module Search

    class Query
      def initialize(&block)
        @value = {}
        self.instance_eval(&block) if block_given?
      end

      def term(field, value)
        @value = { :term => { field => value } }
      end

      def terms(field, value, options={})
        @value = { :terms => { field => value } }
        @value[:terms].update( { :minimum_match => options[:minimum_match] } ) if options[:minimum_match]
        @value
      end

      def string(value, options={})
        @value = { :query_string => { :query => value } }
        @value[:query_string].update(options)
        # TODO: https://github.com/elasticsearch/elasticsearch/wiki/Query-String-Query
        @value
      end

      def boolean(options={}, &block)
        # TODO: Try to get rid of the `boolean` method
        raise ArgumentError, "Please pass a block to boolean query" unless block_given?
        @value = BooleanQuery.new(options, &block).to_hash
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
        self.instance_eval(&block)
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
        { :bool => @value.update(@options) }
      end
    end

  end
end
