module Slingshot
  module Search

    # http://www.elasticsearch.org/guide/reference/api/search/filter.html
    # http://www.elasticsearch.org/guide/reference/query-dsl/
    #
    class Filter

      def initialize(type, *options)
        @type    = type
        @options = options || []
      end

      def to_json
        to_hash.to_json
      end

      def to_hash
        initial = @options.size > 1 ? { @type => [] } : { @type => {} }
        method  = initial[@type].is_a?(Hash) ? :update : :push
        @options.inject(initial) do |hash, option|
          hash[@type].send(method, option)
          hash
        end
      end
    end

  end
end
