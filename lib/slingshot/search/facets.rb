module Slingshot
  module Search

    #--
    # TODO: Implement all elastic search facets (geo, histogram, range, etc)
    # https://github.com/elasticsearch/elasticsearch/wiki/Search-API-Facets
    #++

    class Facets

      def initialize(name, options={}, &block)
        @name = name
        self.instance_eval(&block) if block_given?
      end

      def terms(field, options={})
        @value = { :terms => { :field => field } }
        @value.update(options)
        self
      end

      def to_json
        request = { @name => @value }
        request.to_json
      end
    end

  end
end
