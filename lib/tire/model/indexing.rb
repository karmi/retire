module Tire
  module Model

    module Indexing

      module ClassMethods

        def mapping
          if block_given?
            @store_mapping = true
            yield
            @store_mapping = false
            create_index_or_update_mapping
          else
            @mapping ||= {}
          end
        end

        def indexes(name, options = {}, &block)
          options[:type] ||= 'string'

          if block_given?
            mapping[name] ||= { :type => 'object', :properties => {} }
            @_nested_mapping = name
            nested = yield
            @_nested_mapping = nil
            self
          else
            if @_nested_mapping
              mapping[@_nested_mapping][:properties][name] = options
            else
              mapping[name] = options
            end
            self
          end
        end

        def store_mapping?
          @store_mapping || false
        end

        def create_index_or_update_mapping
          # STDERR.puts "Creating index with mapping", mapping_to_hash.inspect
          # STDERR.puts "Index exists?, #{index.exists?}"
          unless elasticsearch_index.exists?
            elasticsearch_index.create :mappings => mapping_to_hash
          else
            # TODO: Update mapping
          end
        rescue Exception => e
          # TODO: STDERR + logger
          raise
        end

        def mapping_to_hash
          { document_type.to_sym => { :properties => mapping } }
        end

      end

    end

  end
end
