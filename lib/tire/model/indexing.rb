module Tire
  module Model

    # Contains logic for definition of index settings and mappings.
    #
    module Indexing

      module ClassMethods

        # Define [_settings_](http://www.elasticsearch.org/guide/reference/api/admin-indices-create-index.html)
        # for the corresponding index, such as number of shards and replicas, custom analyzers, etc.
        #
        # Usage:
        #
        #     class Article
        #       # ...
        #       settings :number_of_shards => 1 do
        #         mapping do
        #           # ...
        #         end
        #       end
        #     end
        #
        def settings(*args)
          @settings ||= {}
          args.empty?  ? (return @settings) : @settings = args.pop
          yield if block_given?
        end

        # Define the [_mapping_](http://www.elasticsearch.org/guide/reference/mapping/index.html)
        # for the corresponding index, telling _Elasticsearch_ how to understand your documents:
        # what type is which property, whether it is analyzed or no, which analyzer to use, etc.
        #
        # You may pass the top level mapping properties (such as `_source` or `_all`) as a Hash.
        #
        # Usage:
        #
        #     class Article
        #       # ...
        #       mapping :_source => { :compress => true } do
        #         indexes :id,    :index    => :not_analyzed
        #         indexes :title, :analyzer => 'snowball', :boost => 100
        #         indexes :words, :as       => 'content.split(/\W/).length'
        #
        #         indexes :comments do
        #           indexes :body
        #           indexes :author do
        #             indexes :name
        #           end
        #         end
        #
        #         # ...
        #       end
        #     end
        #
        def mapping(*args)
          @mapping ||= {}
          if block_given?
            @mapping_options = args.pop
            yield
            create_elasticsearch_index
          else
            @mapping
          end
        end

        # Define mapping for the property passed as the first argument (`name`)
        # using definition from the second argument (`options`).
        #
        # `:type` is optional and defaults to `'string'`.
        #
        # Usage:
        #
        # * Index property but do not analyze it: `indexes :id, :index    => :not_analyzed`
        #
        # * Use different analyzer for indexing a property: `indexes :title, :analyzer => 'snowball'`
        #
        # * Use the `:as` option to dynamically define the serialized property value, eg:
        #
        #       :as => 'content.split(/\W/).length'
        #
        # Please refer to the
        # [_mapping_ documentation](http://www.elasticsearch.org/guide/reference/mapping/index.html)
        # for more information.
        #
        def indexes(name, options = {}, &block)
          mapping[name] = options

          if block_given?
            mapping[name][:type]       ||= 'object'
            mapping[name][:properties] ||= {}

            previous = @mapping
            @mapping = mapping[name][:properties]
            yield
            @mapping = previous
          end

          mapping[name][:type] ||= 'string'

          self
        end

        # Creates the corresponding index with desired settings and mappings, when it does not exists yet.
        #
        def create_elasticsearch_index
          unless index.exists?
            new_index = index
            unless result = new_index.create(:mappings => mapping_to_hash, :settings => settings)
              STDERR.puts "[ERROR] There has been an error when creating the index -- elasticsearch returned:",
                          new_index.response
              result
            end
          end

        rescue *Tire::Configuration.client.__host_unreachable_exceptions => e
          STDERR.puts "Skipping index creation, cannot connect to Elasticsearch",
                      "(The original exception was: #{e.inspect})"
          false
        end

        def mapping_options
          @mapping_options || {}
        end

        def mapping_to_hash
          { document_type.to_sym => mapping_options.merge({ :properties => mapping }) }
        end

      end

    end

  end
end
