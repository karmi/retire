module Tire
  module Model

    # Contains logic for getting and setting the index name and document type for this model.
    #
    module Naming

      module ClassMethods

        # Get or set the index name for this model, based on arguments.
        #
        # By default, uses ActiveSupport inflection, so a class named `Article`
        # will be stored in the `articles` index.
        #
        # To get the index name:
        #
        #     Article.index_name
        #
        # To set the index name:
        #
        #     Article.index_name 'my-custom-name'
        #
        def index_name name=nil
          @index_name = name if name
          @index_name || "#{Model::Search.index_prefix.nil? ? '' : Model::Search.index_prefix}#{klass.model_name.plural}"
        end

        # Get or set the document type for this model, based on arguments.
        #
        # By default, uses ActiveSupport inflection, so a class named `Article`
        # will be stored as the `article` type.
        #
        # To get the document type:
        #
        #     Article.document_type
        #
        # To set the document type:
        #
        #     Article.document_type 'my-custom-type'
        #
        def document_type name=nil
          @document_type = name if name
          @document_type || klass.model_name.singular
        end
      end

      module InstanceMethods

        # Proxy to class method `index_name`.
        #
        def index_name
          instance.class.tire.index_name
        end

        # Proxy to instance method `document_type`.
        #
        def document_type
          instance.class.tire.document_type
        end
      end

    end

  end
end
