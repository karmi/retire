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

        def indexes(name, options = {})
          # p "#{self}, SEARCH PROPERTY, #{name}"
          mapping[name] = options
        end

        def store_mapping?
          @store_mapping || false
        end

        def create_index_or_update_mapping
          # STDERR.puts "Creating index with mapping", mapping_to_hash.inspect
          # STDERR.puts "Index exists?, #{index.exists?}"
          unless index.exists?
            index.create :mappings => mapping_to_hash
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
