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
        @wrapper  = options[:wrapper] || Configuration.wrapper
      end

      def results
        @results ||= begin
          hits = @response['hits']['hits']
          unless @options[:load]
            if @wrapper == Hash
              hits
            else
              hits.map do |h|
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
          else
            return [] if hits.empty?

            load_options = options[:load] === true ? {} : options[:load]

            # Collect all ids of one type to perform one database query per type
            records_by_type = {}
            hits.group_by { |hit| hit['_type'] }.each do |type, hits|
              raise NoMethodError, "You have tried to eager load the model instances, " +
                                   "but Tire cannot find the model class because " +
                                   "document has no _type property." unless type
              ids = hits.map{ |hit| hit['_id'] }
              begin
                model = type.camelize.constantize
              rescue NameError => e
                raise NameError, "Cannot find the model class '#{type.camelize}' " +
                                 "based on _type '#{type}' during eager loading.", e.backtrace
              end
              records = model.where(model.primary_key => ids).all(load_options)
              records_by_type[type] = records.index_by(&:id)
            end
            # Preserve original order from search results
            records = hits.map { |hit| records_by_type[hit['_type']][hit['_id'].to_i] }
            records.compact!

            # Remove missing records from the total
            @total -= hits.size - records.size

            records
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
      alias :length :size

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
