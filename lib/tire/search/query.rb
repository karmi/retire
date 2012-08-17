module Tire
  module Search

    class Query
      def initialize(&block)
        @value = {}
        block.arity < 1 ? self.instance_eval(&block) : block.call(self) if block_given?
      end

      def term(field, value, options={})
        query = { field => { :term => value }.update(options) }
        @value = { :term => query }
      end

      def terms(field, value, options={})
        @value = { :terms => { field => value } }
        @value[:terms].update( { :minimum_match => options[:minimum_match] } ) if options[:minimum_match]
        @value
      end

      def range(field, value)
        @value = { :range => { field => value } }
      end

      def text(field, value, options={})
        query_options = { :query => value }.update(options)
        @value = { :text => { field => query_options } }
        @value
      end

      def string(value, options={})
        @value = { :query_string => { :query => value } }
        @value[:query_string].update(options)
        @value
      end

      def prefix(field, value, options={})
        if options[:boost]
          @value = { :prefix => { field => { :prefix => value, :boost => options[:boost] } } }
        else
          @value = { :prefix => { field => value } }
        end
      end

      def custom_boost_factor(options={}, &block)
        @custom_boost_factor ||= Query.new(&block)
        @value[:custom_boost_factor] = options
        @value[:custom_boost_factor].update({:query => @custom_boost_factor.to_hash})
        @value
      end

      def custom_score(options={}, &block)
        @custom_score ||= Query.new(&block)
        @value[:custom_score] = options
        @value[:custom_score].update({:query => @custom_score.to_hash})
        @value
      end

      def fuzzy(field, value, options={})
        query = { field => { :term => value }.update(options) }
        @value = { :fuzzy => query }
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

      def span_first(options={}, &block)
        @span_first = SpanFirstQuery.new(options)
        block.arity < 1 ? @span_first.instance_eval(&block) : block.call(@span_first) if block_given?
        @value[:span_first] = @span_first.to_hash
        @value
      end

      def span_near(options={}, &block)
        @span_near = SpanNearOrQuery.new(options)
        block.arity < 1 ? @span_near.instance_eval(&block) : block.call(@span_near) if block_given?
        @value[:span_near] = @span_near.to_hash
        @value
      end

      def span_or(options={}, &block)
        @span_or = SpanNearOrQuery.new(options)
        block.arity < 1 ? @span_or.instance_eval(&block) : block.call(@span_or) if block_given?
        @value[:span_or] = @span_or.to_hash
        @value
      end

      def dis_max(options={}, &block)
        @dis_max ||= DisMaxQuery.new(options)
        block.arity < 1 ? @dis_max.instance_eval(&block) : block.call(@dis_max) if block_given?
        @value[:dis_max] = @dis_max.to_hash
        @value
      end

      def nested(path, options={}, &block)
        @nested ||= Query.new(&block)
        @value[:nested] = options
        @value[:nested].update({ path: path, query: @nested.to_hash })
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
        @value[:filter] ||= {}
        @value[:filter][:and] ||= []
        @value[:filter][:and] << Filter.new(type, *options).to_hash
        @value
      end

      def to_hash
        @value
      end

      def to_json
        to_hash.to_json
      end
    end

    class SpanNearOrQuery
      def initialize(options={}, &block)
        @options = options
        @value   = {}
        block.arity < 1 ? self.instance_eval(&block) : block.call(self) if block_given?
      end

      def span_term(field, value, options={})
        @value[:clauses] ||= []
        @value[:clauses] << { :span_term => { field => value }.update(options) }
      end

      def to_hash
        @value.update(@options)
      end

      def to_json
        to_hash.to_json
      end
    end

    class SpanFirstQuery
      def initialize(options={}, &block)
        @options = { :end => 1 }.update(options)
        @value   = {}
        block.arity < 1 ? self.instance_eval(&block) : block.call(self) if block_given?
      end

      def span_term(field, value, options={})
        @value[:match] = { :span_term => { field => value }.update(options) }
      end

      def to_hash
        @value.update(@options)
      end

      def to_json
        to_hash.to_json
      end
    end

    class DisMaxQuery
      def initialize(options={}, &block)
        @options = options
        @value   = {}
        block.arity < 1 ? self.instance_eval(&block) : block.call(self) if block_given?
      end

      def query(&block)
        (@value[:queries] ||= []) << Query.new(&block).to_hash
        @value
      end

      def to_hash
        @value.update(@options)
      end

      def to_json
        to_hash.to_json
      end
    end
  end
end
