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
               document = h['_source'] ? document.update( h['_source'] || {} ) : document.update( __parse_fields__(h['fields']) )
               document.update( {'id' => h['_id']} )

               # Update the document with meta information
               ['_score', '_type', '_index', '_version', 'sort', 'highlight'].each { |key| document.update( {key => h[key]} || {} ) }

               # Return an instance of the "wrapper" class
               @wrapper.new(document)
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

      # Handles _source prefixed fields properly: strips the prefix and converts fields to nested Hashes
      #
      def __parse_fields__(fields={})
        ( fields ||= {} ).clone.each_pair do |key,value|
          next unless key.to_s =~ /_source/                 # Skip regular JSON immediately

          keys = key.to_s.split('.').reject { |n| n == '_source' }
          fields.delete(key)

          result = {}
          path = []

          keys.each do |name|
            path << name
            eval "result[:#{path.join('][:')}] ||= {}"
            eval "result[:#{path.join('][:')}] = #{value.inspect}" if keys.last == name
          end
          fields.update result
        end
        fields
      end

    end

  end
end
