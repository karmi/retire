module Slingshot
  module Results

    class Collection
      include Enumerable
      attr_reader :time, :total, :results, :facets

      def initialize(response)
        @time    = response['took']
        @total   = response['hits']['total']
        @results = response['hits']['hits'].map do |h|
                     if Configuration.wrapper == Hash
                       h
                     else
                       document = h['_source'] ? h['_source'] : h['fields']
                       h.update document if document
                       Configuration.wrapper.new(h)
                     end
                   end
        @facets  = response['facets']
      end

      def each(&block)
        @results.each(&block)
      end

    end

  end
end
