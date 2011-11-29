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
        # for the corresponding index, telling _ElasticSearch_ how to understand your documents:
        # what type is which property, whether it is analyzed or no, which analyzer to use, etc.
        #
        # You may pass the top level mapping properties (such as `_source` or `_all`) as a Hash.
        #
        # Usage:
        #
        #     class Article
        #       # ...
        #       mapping :_source => { :compress => true } do
        #         indexes :id,    :type => 'string',  :index    => :not_analyzed
        #         indexes :title, :type => 'string',  :analyzer => 'snowball',   :boost => 100
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
        # Please refer to the
        # [_mapping_ documentation](http://www.elasticsearch.org/guide/reference/mapping/index.html)
        # for more information.
        #
        def indexes(name, options = {}, &block)
          if block_given?
            mapping[name] ||= { :type => 'object', :properties => {} }.update(options)
            @_nested_mapping = name
            nested = yield
            @_nested_mapping = nil
            self
          else
            options[:type] ||= 'string'
            if @_nested_mapping
              mapping[@_nested_mapping][:properties][name] = options
            else
              mapping[name] = options
            end
            self
          end
        end

        # Creates the corresponding index with desired settings and mappings, when it does not exists yet.
        #
        def create_elasticsearch_index
          unless index.exists?
            index.create :mappings => mapping_to_hash, :settings => settings
          end
        rescue Errno::ECONNREFUSED => e
          STDERR.puts "Skipping index creation, cannot connect to ElasticSearch",
                      "(The original exception was: #{e.inspect})"
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
