module Slingshot
  module Results

    class Collection
      include Enumerable
      attr_reader :time, :total, :results, :facets

      def initialize(response)
        @time    = response['took']
        @total   = response['hits']['total']
        @results = response['hits']['hits']
        @facets  = response['facets']
      end

      def each(&block)
        @results.each(&block)
      end

    end

  end
end
