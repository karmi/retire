module Slingshot
  module Search

    #--
    # TODO: Implement all elastic search facets (geo, histogram, range, etc)
    # https://github.com/elasticsearch/elasticsearch/wiki/Search-API-Facets
    #++

    class Facet

      def initialize(name, options={}, &block)
        @name    = name
        @options = options
        self.instance_eval(&block) if block_given?
      end

      def terms(field, options={})
        @value = { :terms => { :field => field } }.update(options)
        self
      end

      def to_json
        to_hash.to_json
      end

      def to_hash
        h = { @name => @value }
        h[@name].update @options
        return h
      end
    end

  end
end
