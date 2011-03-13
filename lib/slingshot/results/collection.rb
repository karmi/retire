module Slingshot
  module Results

    class Collection
      include Enumerable
      attr_reader :time, :total, :results, :facets

      def initialize(response)
        @time    = response['took']
        @total   = response['hits']['total']
        @results = response['hits']['hits'].map do |h|
                     if Configuration.wrapper == Hash then h
                     else
                       document = h['fields'] ? h.delete('fields') : h.delete('_source')
                       document['highlight'] = h['highlight'] if h['highlight']
                       h.update document if document
                       Configuration.wrapper.new(h)
                     end
                   end
        @facets  = response['facets']
      end

      def each(&block)
        @results.each(&block)
      end

      def empty?
        @results.empty?
      end

      def size
        @results.size
      end
    end

  end
end
