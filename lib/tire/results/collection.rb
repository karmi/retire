module Tire
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
                       handle_inner_object_fields document

                       # Update the document with meta information
                       ['_score', '_type', '_index', '_version', 'sort', 'highlight'].each { |key| document.update( {key => h[key]} || {} ) }

                       object = Configuration.wrapper.new(document)
                       # TODO: Figure out how to circumvent mass assignment protection for id in ActiveRecord
                       object.id = h['_id'] if object.respond_to?(:id=)
                       # TODO: Figure out how mark record as "not new record" in ActiveRecord
                       object.instance_variable_set(:@new_record, false) if object.respond_to?(:new_record?)
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

      def [](index)
        @results[index]
      end

      def to_ary
        self
      end
      
      private
      
      def handle_inner_object_fields(document)
        symbol_table = {}
        keys_to_delete = []
        
        document.each do |k, v|
          if k.to_s.match /^_source./
            add_to_symbol_table( symbol_table, k, v )
            keys_to_delete << k
          end
        end
        
        keys_to_delete.each {|k| document.delete( k )}
        
        document.update symbol_table
      end
      
      def add_to_symbol_table(symbol_table, k, v)
        exploded_keys = k.sub('_source.', '').split('.')
        variable_name = exploded_keys.pop

        current_hash = symbol_table
        exploded_keys.each do |key|
          new_hash = current_hash[key] && current_hash[key].is_a?(Hash) ? current_hash[key] : {}
          current_hash[key] = new_hash
          current_hash = new_hash
        end
        current_hash[ variable_name ] = v
      end

    end
  end
end
