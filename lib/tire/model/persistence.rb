module Tire
  module Model

    # Allows to use _ElasticSearch_ as a primary database (storage).
    #
    # Contains all the `Tire::Model::Search` features and provides
    # an [_ActiveModel_](http://rubygems.org/gems/activemodel)-compatible
    # interface for persistance.
    #
    # Usage:
    #
    #     class Article
    #       include Tire::Model::Persistence
    #     
    #       property :title
    #     end
    #
    #     Article.create :id => 1, :title => 'One'
    #
    #     article = Article.find
    #
    #     article.destroy
    #
    module Persistence

      def self.included(base)

        base.class_eval do
          include ActiveModel::AttributeMethods
          include ActiveModel::Validations
          include ActiveModel::Serialization
          include ActiveModel::Serializers::JSON
          include ActiveModel::Naming
          include ActiveModel::Conversion

          extend  ActiveModel::Callbacks
          define_model_callbacks :save, :destroy

          include Tire::Model::Search
          include Tire::Model::Callbacks

          extend  Persistence::Finders::ClassMethods
          extend  Persistence::Attributes::ClassMethods
          include Persistence::Attributes::InstanceMethods

          include Persistence::Storage

          ['_score', '_type', '_index', '_version', 'sort', 'highlight', 'matches', '_explanation'].each do |attr|
            define_method("#{attr}=") { |value| @attributes ||= {}; @attributes[attr] = value }
            define_method("#{attr}")  { @attributes ||= {}; @attributes[attr] }
          end

          def self.search(*args, &block)
            # Update options Hash with the wrapper definition
            args.last.update(:wrapper => self) if args.last.is_a? Hash
            args << { :wrapper => self }       unless args.any? { |a| a.is_a? Hash }

            self.__search_without_persistence(*args, &block)
          end

          def self.__search_without_persistence(*args, &block)
            self.tire.search(*args, &block)
          end

        end

      end

    end

  end
end
