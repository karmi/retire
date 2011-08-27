module Tire
  module Model

    module Search

      module ClassMethods

        # Returns search results for a given query.
        #
        # Query can be passed simply as a String:
        #
        #   Article.search 'love'
        #
        # Any options, such as pagination or sorting, can be passed as a second argument:
        #
        #   Article.search 'love', :per_page => 25, :page => 2
        #   Article.search 'love', :sort => 'title'
        #
        # For more powerful query definition, use the query DSL passed as a block:
        #
        #   Article.search do
        #     query { terms :tags, ['ruby', 'python'] }
        #     facet 'tags' { terms :tags }
        #   end
        #
        # You can pass options as the first argument, in this case:
        #
        #   Article.search :per_page => 25, :page => 2 do
        #     query { string 'love' }
        #   end
        #
        #
        def search(*args, &block)
          default_options = {:type => document_type, :index => index.name}

          if block_given?
            options = args.shift || {}
          else
            query, options = args
            options ||= {}
          end

          sort      = Array( options[:order] || options[:sort] )
          options   = default_options.update(options)

          s = Tire::Search::Search.new(options.delete(:index), options)
          s.size( options[:per_page].to_i ) if options[:per_page]
          s.from( options[:page].to_i <= 1 ? 0 : (options[:per_page].to_i * (options[:page].to_i-1)) ) if options[:page] && options[:per_page]
          s.sort do
            sort.each do |t|
              field_name, direction = t.split(' ')
              by field_name, direction
            end
          end unless sort.empty?

          if block_given?
            block.arity < 1 ? s.instance_eval(&block) : block.call(s)
          else
            s.query { string query }
          end

          s.perform.results
        end

        # Wraps an Index instance for this class
        #
        def index
          @index = Index.new(index_name)
        end

      end

      module InstanceMethods

        def index
          instance.class.tire.index
        end

        def update_index
          instance.send :_run_update_elasticsearch_index_callbacks do
            if instance.destroyed?
              index.remove instance
            else
              response  = index.store( instance, {:percolate => percolator} )
              instance.id     ||= response['_id']      if instance.respond_to?(:id=)
              instance._index   = response['_index']   if instance.respond_to?(:_index=)
              instance._type    = response['_type']    if instance.respond_to?(:_type=)
              instance._version = response['_version'] if instance.respond_to?(:_version=)
              instance.matches  = response['matches']  if instance.respond_to?(:matches=)
              self
            end
          end
        end
        alias :update_elasticsearch_index  :update_index
        alias :update_elastic_search_index :update_index

        def to_indexed_json
          if instance.class.tire.mapping.empty?
            instance.to_hash.to_json
          else
            instance.to_hash.
            reject { |key, value| ! instance.class.tire.mapping.keys.map(&:to_s).include?(key.to_s) }.
            to_json
          end
        end

      end

      module Loader

        # Load the "real" model from the database via the corresponding model's `find` method
        #
        def load(options=nil)
          options ? self.class.find(self.id, options) : self.class.find(self.id)
        end

      end

      class ClassMethodsProxy
        include Tire::Model::Naming::ClassMethods
        include Tire::Model::Import::ClassMethods
        include Tire::Model::Indexing::ClassMethods
        include Tire::Model::Percolate::ClassMethods
        include ClassMethods

        INTERFACE = public_instance_methods.map(&:to_sym) - Object.public_instance_methods.map(&:to_sym)

        attr_reader :klass
        def initialize(klass)
          @klass = klass
        end

      end

      class InstanceMethodsProxy
        include Tire::Model::Naming::InstanceMethods
        include Tire::Model::Percolate::InstanceMethods
        include InstanceMethods

        ['_score', '_type', '_index', '_version', 'sort', 'highlight', 'matches'].each do |attr|
          # TODO: Find a sane way to add attributes like _score for ActiveRecord -
          #       `define_attribute_methods [attr]` does not work in AR.
          define_method("#{attr}=") { |value| @attributes ||= {}; @attributes[attr] = value }
          define_method("#{attr}")  { @attributes[attr] }
        end

        INTERFACE = public_instance_methods.map(&:to_sym) - Object.public_instance_methods.map(&:to_sym)

        attr_reader :instance
        def initialize(instance)
          @instance = instance
        end
      end

      def self.included(base)
        base.class_eval do
          def self.tire &block
            @__tire__ ||= ClassMethodsProxy.new(self)

            @__tire__.instance_eval(&block) if block_given?
            @__tire__
          end

          def tire &block
            @__tire__ ||= InstanceMethodsProxy.new(self)

            @__tire__.instance_eval(&block) if block_given?
            @__tire__
          end

          def to_hash
            self.serializable_hash
          end unless instance_methods.map(&:to_sym).include?(:to_hash)

        end

        ClassMethodsProxy::INTERFACE.each do |method|
          base.class_eval <<-"end;", __FILE__, __LINE__ unless base.public_methods.map(&:to_sym).include?(method.to_sym)
            def self.#{method}(*args, &block)
              tire.__send__(#{method.inspect}, *args, &block)
            end
          end;
        end

        InstanceMethodsProxy::INTERFACE.each do |method|
          base.class_eval <<-"end;", __FILE__, __LINE__ unless base.instance_methods.map(&:to_sym).include?(method.to_sym)
            def #{method}(*args, &block)
              tire.__send__(#{method.inspect}, *args, &block)
            end
          end;
        end

        Results::Item.send :include, Loader
      end

    end

  end
end
