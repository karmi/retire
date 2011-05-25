module Tire
  module Search

    #--
    # TODO: Implement all elastic search facets (geo, histogram, range, etc)
    # http://elasticsearch.org/guide/reference/api/search/facets/
    #++

    class Facet

      def initialize(name, options={}, &block)
        @name    = name
        @options = options
        self.instance_eval(&block) if block_given?
      end

      def terms(field, options={})
        size      = options.delete(:size) || 10
        all_terms = options.delete(:all_terms) || false
        @value = { :terms => { :field => field, :size => size, :all_terms => all_terms } }.update(options)
        self
      end

      def date(field, options={})
        interval = options.delete(:interval) || 'day'
        @value = { :date_histogram => { :field => field, :interval => interval } }.update(options)
        self
      end

      def range(field, ranges=[], options={})
        @value = { :range => { :field => field, :ranges => ranges }.update(options) }
      end

      def to_json
        to_hash.to_json
      end

      def to_hash
        @value.update @options
        { @name => @value }
      end
    end

  end
end
