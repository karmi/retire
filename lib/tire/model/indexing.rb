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
        # Usage:
        #
        #     class Article
        #       # ...
        #       mapping do
        #         indexes :id,    :type => 'string',  :index    => :not_analyzed
        #         indexes :title, :type => 'string',  :analyzer => 'snowball',   :boost => 100
        #         # ...
        #       end
        #     end
        #
        def mapping
          @mapping ||= {}
          if block_given?
            @store_mapping = true and yield and @store_mapping = false
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

        # Define the [_dynamic_templates_](http://www.elasticsearch.org/guide/reference/mapping/root-object-type.html)
        # for the corresponding index, telling _ElasticSearch_ how to understand your documents:
        # how to process dynamic mappings, whether it is analyzed or no, which analyzer to use, etc.
        #
        # Usage:
        #
        #     class Article
        #       # ...
        #       mapping do
        #         dynamic_template do
        #           templates :string, :match => "*", :match_mapping_type => "string", :mapping => {:type => "string", :store => 'no', :index => 'analyzed', :include_in_all => true}
        #            templates :long, :match => "*", :match_mapping_type => "long", :mapping => {:type => "long", :store => 'no', :include_in_all => false}
        #            # ....
        #         end
        #
        #         indexes :id,    :type => 'string',  :index    => :not_analyzed
        #         indexes :title, :type => 'string',  :analyzer => 'snowball',   :boost => 100
        #         # ...
        #       end
        #     end
        #
        def dynamic_template
          @dynamic_template ||= {}
          if block_given?
            yield
          else
            @dynamic_template
          end
        end

        # Define dynamic template for the property passed as the first argument (`name`)
        # using definition from the second argument (`options`).
        #
        # Usage:
        #
        # * Index all strings and analyze them: `indexes :string, :match => "*", :match_mapping_type => "string", :mapping => {:type => "string", :index => :analyzed}`
        #
        # * Use different analyzer for indexing a property: `indexes :title, :analyzer => 'snowball'`
        #
        # Please refer to the
        # [_object_type_ documentation](http://www.elasticsearch.org/guide/reference/mapping/object-type.html)
        # for more information.
        #
        def templates(name, options = {}, &block)
          if block_given?
            dynamic_template[name] ||= { :type => 'object', :properties => {} }
            @_nested_template = name
            nested = yield
            @_nested_template = nil
            self
          else
            if @_nested_template
              dynamic_template[@_nested_template][:properties][name] = options
            else
              dynamic_template[name] = options
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

        def store_mapping?
          @store_mapping || false
        end

        def mapping_to_hash
          mh = { :properties => mapping }
          unless dynamic_template.empty?
            mh[:dynamic_templates] = dynamic_template.map { |k, v| {k => v} }
          end
          { document_type.to_sym => mh }
        end

      end

    end

  end
end
