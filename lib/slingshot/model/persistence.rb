module Slingshot
  module Model

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

          include Slingshot::Model::Search
          include Slingshot::Model::Callbacks

          extend  Persistence::Finders::ClassMethods
          extend  Persistence::Attributes::ClassMethods
          include Persistence::Attributes::InstanceMethods

          include Persistence::Storage
        end

      end

    end

  end
end
