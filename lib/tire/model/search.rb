module Tire
  module Model

    module Search

      def self.included(base)
        base.class_eval do
          extend  Tire::Model::Naming::ClassMethods
          include Tire::Model::Naming::InstanceMethods

          extend  Tire::Model::Indexing::ClassMethods
          extend  Tire::Model::Import::ClassMethods

          extend  Tire::Model::Percolate::ClassMethods
          include Tire::Model::Percolate::InstanceMethods

          extend  ClassMethods
          include InstanceMethods

          ['_score', '_type', '_index', '_version', 'sort', 'highlight', 'matches'].each do |attr|
            # TODO: Find a sane way to add attributes like _score for ActiveRecord -
            #       `define_attribute_methods [attr]` does not work in AR.
            define_method("#{attr}=") { |value| @attributes ||= {}; @attributes[attr] = value }
            define_method("#{attr}")  { @attributes[attr] }
          end

          def to_hash
            self.serializable_hash
          end unless instance_methods.map(&:to_sym).include?(:to_hash)
        end

        Results::Item.send :include, Loader
      end

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
          default_options = {:type => document_type}

          if block_given?
            options = args.shift || {}
          else
            query, options = args
            options ||= {}
          end

          sort      = Array( options[:order] || options[:sort] )
          options   = default_options.update(options)
          
          if options.fetch(:index_name, nil)
            s = Tire::Search::Search.new(options.delete(:index_name), options)
          else
            s = Tire::Search::Search.new(elasticsearch_index.name, options)
          end
          
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

        # Wrapper for the ES index for this class
        #
        # TODO: Implement some "forwardable" object named +tire+ for Tire mixins,
        #       and proxy everything via this object. If we're not stepping on
        #       other libs toes, extend/include also to the top level.
        #
        #       The original culprit is Mongoid here, see https://github.com/karmi/tire/issues/7
        #
        def elasticsearch_index
          @index = Index.new(index_name)
        end

      end

      module InstanceMethods

        def index
          self.class.elasticsearch_index
        end

        def update_elastic_search_index
          _run_update_elastic_search_index_callbacks do
            if destroyed?
              index.remove self
            else
              response  = index.store( self, {:percolate => self.percolator} )
              self.id ||= response['_id'] if self.respond_to?(:id=)
              self._index   = response['_index']
              self._type    = response['_type']
              self._version = response['_version']
              self.matches  = response['matches']
              self
            end
          end
        end
        alias :update_elasticsearch_index :update_elastic_search_index

        def to_indexed_json
          if self.class.mapping.empty?
            to_hash.to_json
          else
            to_hash.
            reject { |key, value| ! self.class.mapping.keys.map(&:to_s).include?(key.to_s) }.
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

      extend ClassMethods
    end

  end
end
