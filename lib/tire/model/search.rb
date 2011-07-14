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

        def search(query=nil, options={}, &block)
          sort    = Array( options[:order] || options[:sort] )
          options = {:type => document_type}.update(options)

          unless block_given?
            s = Tire::Search::Search.new(elasticsearch_index.name, options)
            s.query { string query }
            s.sort do
              sort.each do |t|
                field_name, direction = t.split(' ')
                by field_name, direction
              end
            end unless sort.empty?
            s.size( options[:per_page].to_i ) if options[:per_page]
            s.from( options[:page].to_i <= 1 ? 0 : (options[:per_page].to_i * (options[:page].to_i-1)) ) if options[:page] && options[:per_page]
            s.perform.results
          else
            s = Tire::Search::Search.new(elasticsearch_index.name, options)
            block.arity < 1 ? s.instance_eval(&block) : block.call(s)
            s.perform.results
          end
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

        def score
          Tire.warn "#{self.class}#score has been deprecated, please use #{self.class}#_score instead."
          attributes['_score']
        end

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
