module Tire
  module Model

    module Indexing

      module ClassMethods

        def settings(*args)
          @settings ||= {}
          args.empty?  ? (return @settings) : @settings = args.pop
          yield if block_given?
        end

        def mapping
          @mapping ||= {}
          if block_given?
            @store_mapping = true and yield and @store_mapping = false
            # Defer index create with dynamic index names
            create_elasticsearch_index unless dynamic_index_name?
          else
            @mapping
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

        def create_elasticsearch_index
          unless index.exists?
            index.create :mappings => mapping_to_hash, :settings => settings
          end
        end

        def mapping_to_hash
          { document_type.to_sym => { :properties => mapping } }
        end

      end

    end

  end
end
