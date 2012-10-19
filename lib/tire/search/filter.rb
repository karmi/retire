module Tire
  module Search

    # http://www.elasticsearch.org/guide/reference/api/search/filter.html
    # http://www.elasticsearch.org/guide/reference/query-dsl/
    #
    class Filter

      def initialize(type, *options)
        value = if options.size < 2
          options.first || {}
        else
          options # An +or+ filter encodes multiple filters as an array
        end
        @hash = { type => value }
      end

      def to_json(options={})
        to_hash.to_json
      end

      def to_hash
        @hash
      end
    end

  end
end
