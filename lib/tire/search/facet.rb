module Tire
  module Search

    class Facet

      def initialize(name, options={}, &block)
        @name    = name
        @options = options
        @value   = {}
        block.arity < 1 ? self.instance_eval(&block) : block.call(self) if block_given?
      end

      def terms(field, options={})
        size      = options.delete(:size) || 10
        all_terms = options.delete(:all_terms) || false
        @value[:terms] = if field.is_a?(Enumerable) and not field.is_a?(String)
          { :fields => field }.update({ :size => size, :all_terms => all_terms }).update(options)
        else
          { :field => field  }.update({ :size => size, :all_terms => all_terms }).update(options)
        end
        self
      end

      def date(field, options={})
        interval = { :interval => options.delete(:interval) || 'day' }
        fields   = options[:value_field] || options[:value_script] ? { :key_field => field } : { :field => field }
        @value[:date_histogram] = {}.update(fields).update(interval).update(options)
        self
      end

      def range(field, ranges=[], options={})
        @value[:range] = { :field => field, :ranges => ranges }.update(options)
        self
      end

      def histogram(field, options={})
        @value[:histogram] = (options.delete(:histogram) || {:field => field}.update(options))
        self
      end

      def statistical(field, options={})
        @value[:statistical] = (options.delete(:statistical) || {:field => field}.update(options))
        self
      end

      def geo_distance(field, point, ranges=[], options={})
        @value[:geo_distance] = { field => point, :ranges => ranges }.update(options)
        self
      end

      def terms_stats(key_field, value_field, options={})
        @value[:terms_stats] = {:key_field => key_field, :value_field => value_field}.update(options)
        self
      end

      def query(&block)
        @value[:query] = Query.new(&block).to_hash
      end

      def filter(type, options={})
        @value[:filter] = Filter.new(type, options)
        self
      end

      def facet_filter(type, *options)
        @value[:facet_filter] = Filter.new(type, *options).to_hash
        self
      end

      def to_json(options={})
        to_hash.to_json
      end

      def to_hash
        @value.update @options
        { @name => @value }
      end
    end

  end
end
