module Tire
  module Results

    class Collection
      include Enumerable
      include Pagination

      attr_reader :time, :total, :options, :facets

      def initialize(response, options={})
        @response = response
        @options  = options
        @time     = response['took'].to_i
        @total    = response['hits']['total'].to_i
        @facets   = response['facets']
        @wrapper  = Configuration.wrapper
      end

      def results
        @results ||= begin
          @response['hits']['hits'].map do |h|
             if @wrapper == Hash then h
             else
               document = {}

               # Update the document with content and ID
               document = h['_source'] ? document.update( h['_source'] || {} ) : document.update( h['fields'] || {} )
               document.update( {'id' => h['_id']} )

               # Update the document with meta information
               ['_score', '_type', '_index', '_version', 'sort', 'highlight'].each { |key| document.update( {key => h[key]} || {} ) }

               # for instantiating ActiveRecord with arbitrary attributes and setting @new_record etc.
               if @wrapper.respond_to?(:instantiate, true)
                 @wrapper.send(:instantiate, document)
               else
                 @wrapper.new(document)
               end
             end
           end
        end
      end

      def each(&block)
        results.each(&block)
      end

      def empty?
        results.empty?
      end

      def size
        results.size
      end

      def [](index)
        results[index]
      end

      def to_ary
        self
      end

    end

  end
end
