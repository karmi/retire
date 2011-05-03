module Tire
  module Model

    module Search

      def self.included(base)
        base.class_eval do
          extend  Tire::Model::Naming::ClassMethods
          include Tire::Model::Naming::InstanceMethods

          extend  Tire::Model::Indexing::ClassMethods
          extend  Tire::Model::Import::ClassMethods

          extend  ClassMethods
          include InstanceMethods

          ['_score', '_type', '_index', '_version', 'sort', 'highlight'].each do |attr|
            # TODO: Find a sane way to add attributes like _score for ActiveRecord -
            #       `define_attribute_methods [attr]` does not work in AR.
            define_method("#{attr}=") { |value| @attributes ||= {}; @attributes[attr] = value }
            define_method("#{attr}")  { @attributes[attr] }
          end
        end
      end

      module ClassMethods

        def search(query=nil, options={}, &block)
          old_wrapper = Tire::Configuration.wrapper
          Tire::Configuration.wrapper self
          sort  = options[:order] || options[:sort]
          sort  = Array(sort)
          unless block_given?
            s = Tire::Search::Search.new(elasticsearch_index.name, options)
            s.query { string query }
            s.sort do
              sort.each do |t|
                field_name, direction = t.split(' ')
                field_name.include?('.') ? field(field_name, direction) : send(field_name, direction)
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
        ensure
          Tire::Configuration.wrapper old_wrapper
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
          attributes['_score']
        end

        def index
          self.class.elasticsearch_index
        end

        def update_elastic_search_index
          if destroyed?
            index.remove document_type, self
          else
            response  = index.store  document_type, self
            self.id ||= response['_id'] if self.respond_to?(:id=)
            self
          end
        end

        def to_indexed_json
          if self.class.mapping.empty?
            self.serializable_hash.
              to_json
          else
            self.serializable_hash.
              reject { |key, value| ! self.class.mapping.keys.map(&:to_s).include?(key.to_s) }.
              to_json
          end
        end

      end

      extend ClassMethods
    end

  end
end
