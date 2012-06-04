module Tire
  class Exception < ::StandardError; end
  class UnknownModel < Tire::Exception
    def initialize(type)
      @type = type
    end

    def message
      "You have tried to eager load the model instances, but " +
      "Tire cannot find the model class '#{@type.camelize}' " +
      "based on _type '#{@type}'."
    end
  end

  class UnknownType < Tire::Exception
    def message
      "You have tried to eager load the model instances, " +
      "but Tire cannot find the model class because " +
      "document has no _type property." 
    end
  end

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
        @results ||= fetch_results
      end

      def hits
        @hits ||= @response['hits']['hits'].map { |d| d.update '_type' => Utils.unescape(d['_type']) }
      end

      def load_records(type, items, options)
        records = {}
        if !options.nil?
          klass = get_class(type)
          ids = items.map { |h| h['_id'] }
          (options === true ? klass.find(ids) : klass.find(ids, options)).each do |item|
            records["#{type}-#{item.id}"] = item
          end
        end
          
        records
      end

      def parse_results(type, items)
        records = load_records(type, items, @options[:load])
        items.map do |h|
          document = {}

          # Update the document with content and ID
          document = h['_source'] ? document.update( h['_source'] || {} ) : document.update( __parse_fields__(h['fields']) )
          document.update( {'id' => h['_id']} )

          # Update the document with meta information
          ['_score', '_type', '_index', '_version', 'sort', 'highlight', '_explanation'].each { |key| document.update( {key => h[key]} || {} ) }

          document.update( {'_type' => Utils.unescape(document['_type'])} )

          document['_model'] = records["#{type}-#{h['_id']}"] if @wrapper == Results::Item

          # Return an instance of the "wrapper" class
          @wrapper.new(document)
        end
      end

      def fetch_results
        return hits if @wrapper == Hash
        records = {}
        hits.group_by { |item| item['_type'] }.each do |type, items|
          records[type] = parse_results(type, items)
        end

        hits.map { |item| records[item['_type']].detect { |record| record.id.to_s == item['_id'].to_s } }
      end

      def get_class(type)
        raise Tire::UnknownType if type.nil? || type.strip.empty?
        klass = type.camelize.constantize
      rescue NameError
        raise Tire::UnknownModel.new(type)
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
