module Slingshot
  module Model

    module Search

      def self.included(base)
        base.class_eval do
          extend  Slingshot::Model::Naming::ClassMethods
          include Slingshot::Model::Naming::InstanceMethods

          extend  ClassMethods
          include InstanceMethods

          base.class_eval do
            ['_score', '_type', '_index'].each do |attr|
              # TODO: Find a sane way to add attributes like _score for ActiveRecord
              define_method("#{attr}=") { |value| instance_variable_get(:@attributes)[attr] = value }
              define_method("#{attr}")  { attributes[attr] }
            end
          end
        end
      end

      module ClassMethods

        def search(query=nil, options={}, &block)
          old_wrapper = Slingshot::Configuration.wrapper
          Slingshot::Configuration.wrapper self
          index = model_name.plural
          sort  = options[:order] || options[:sort]
          sort  = Array(sort)
          unless block_given?
            s = Slingshot::Search::Search.new(index, options)
            s.query { string query }
            s.sort do
              sort.each do |t|
                field_name, direction = t.split(' ')
                field_name.include?('.') ? field(field_name, direction) : send(field_name, direction)
              end
            end unless sort.empty?
            s.perform.results
          else
            s = Slingshot::Search::Search.new(index, options, &block).perform.results
          end
        ensure
          Slingshot::Configuration.wrapper old_wrapper
        end

      end

      module InstanceMethods

        def score
          attributes['_score']
        end

        def _id=(value)
          self.id=value
        end

        def update_index
          if destroyed?
            Index.new(index_name).remove document_type, self
          else
            Index.new(index_name).store  document_type, self
          end
        end

        def to_indexed_json
          self.serializable_hash.to_json
        end

      end

      extend ClassMethods
    end

  end
end
