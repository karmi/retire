module Slingshot
  module Results

    class Collection
      include Enumerable
      attr_reader :time, :total, :results, :facets

      def initialize(response)
        @time    = response['took']
        @total   = response['hits']['total']
        @results = if Configuration.wrapper.respond_to?(:mode) && Configuration.wrapper.mode == :searchable
          # FIXME: `SELECT ... IN` SQL query does not preserve sort order
          Configuration.wrapper.find response['hits']['hits'].map { |h| h['_id'] }
        else
          response['hits']['hits'].map do |h|
                       if Configuration.wrapper == Hash
                         h
                       else
                         document = h['fields'] ? h.delete('fields') : h.delete('_source')
                         document['highlight'] = h['highlight'] if h['highlight']
                         h.update document if document
                         Configuration.wrapper.new(h)
                       end
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
