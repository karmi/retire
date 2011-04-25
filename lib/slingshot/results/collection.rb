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
                       document = {}

                       # Update the document with content and ID
                       document = h['_source'] ? document.update( h['_source'] || {} ) : document.update( h['fields'] || {} )
                       document.update( {'id' => h['_id']} )

                       # Update the document with meta information
                       ['_score', '_version', 'sort', 'highlight'].each { |key| document.update( {key => h[key]} || {} ) }

                       # TODO: Find a way to actually circumvent mass assignment in ActiveRecord and this wouldn't be neccessary
                       object = Configuration.wrapper.new(document)
                       object.id = h['_id'] if object.respond_to?(:id=)
                       object
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
