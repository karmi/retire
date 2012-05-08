module Tire
  module Results

    class MultiGetCollection
      include Enumerable

      attr_reader :options

      def initialize(response, options={})
        @response = response
        @options  = options
        @wrapper  = options[:wrapper] || Configuration.wrapper
      end

      def results
        @results ||= begin
          docs = @response['docs'].map { |d| d.update '_type' => Utils.unescape(d['_type']) }

          unless @options[:load]
            if @wrapper == Hash
              docs
            else
              docs.map do |h|
                if h['exists']
                  document = {}

                  # Update the document with content and ID
                  document = h['_source'] ? document.update( h['_source'] || {} ) : document.update( __parse_fields__(h['fields']) )
                  document.update( {'id' => h['_id']} )

                  # Update the document with meta information
                  ['_type', '_index', '_version'].each { |key| document.update( {key => h[key]} || {} ) }

                  # Return an instance of the "wrapper" class
                  if @wrapper.respond_to?(:call)
                    @wrapper.call(document)
                  else
                    @wrapper.new(document)
                  end
                end
              end
            end

          else
            return [] if docs.empty?

            records = {}
            @response['docs'].group_by { |item| item['_type'] }.each do |type, items|
              raise NoMethodError, "You have tried to eager load the model instances, " +
                                   "but Tire cannot find the model class because " +
                                   "document has no _type property." unless type

              begin
                klass = type.camelize.constantize
              rescue NameError => e
                raise NameError, "You have tried to eager load the model instances, but " +
                                 "Tire cannot find the model class '#{type.camelize}' " +
                                 "based on _type '#{type}'.", e.backtrace
              end
              ids = items.map { |h| h['_id'] }
              records[type] = @options[:load] === true ? klass.find(ids) : klass.find(ids, @options[:load])
            end

            # Reorder records to preserve order from search results
            @response['docs'].map { |item| records[item['_type']].detect { |record| record.id.to_s == item['_id'].to_s } }
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
