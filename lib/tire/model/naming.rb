module Tire
  module Model

    # Contains logic for getting and setting the index name and document type for this model.
    #
    module Naming

      module ClassMethods

        # Get or set the index name for this model, based on arguments.
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
          @index_name || klass.model_name.plural
        end

        # Get the document type for this model, based on the class name.
        #
        def document_type
          klass.model_name.singular
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
