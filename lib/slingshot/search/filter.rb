module Slingshot
  module Search

    # http://www.elasticsearch.org/guide/reference/api/search/filter.html
    # http://www.elasticsearch.org/guide/reference/query-dsl/
    #
    class Filter

      def initialize(type, *options)
        value = if options.size < 2
          options.first || {}
        else
          options
        end
        @hash = { type => value }
      end

      def to_json
        to_hash.to_json
      end

      def to_hash
        @hash
      end
    end

  end
end
