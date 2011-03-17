module Slingshot
  module Results

    class Collection
      include Enumerable
      include Pagination

      attr_reader :time, :total, :options, :results, :facets

      def initialize(response, options={})
        @options = options
        @time    = response['took'].to_i
        @total   = response['hits']['total'].to_i
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

      def to_ary
        self
      end

    end

  end
end
