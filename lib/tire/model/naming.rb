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
        # You can also use a block for defining the index name,
        # which is evaluated in the class context:
        #
        #     Article.index_name { "articles-#{Time.now.year}" }
        #
        #     Article.index_name { "articles-#{Rails.env}" }
        #
        def index_name name=nil, &block
          @index_name = name if name
          @index_name = block if block_given?
          # TODO: Try to get index_name from ancestor classes
          @index_name || [index_prefix, klass.model_name.plural].compact.join('_')
        end

        # Set or get index prefix for all models or for a specific model.
        #
        # To set the prefix for all models (preferably in an initializer inside Rails):
        #
        #     Tire::Model::Search.index_prefix Rails.env
        #
        # To set the prefix for specific model:
        #
        #     class Article
        #       # ...
        #       index_prefix 'my_prefix'
        #     end
        #
        # TODO: Maybe this would be more sane with ActiveSupport extensions such as `class_attribute`?
        #
        @@__index_prefix__ = nil
        def index_prefix(*args)
          # Uses class or instance variable depending on the context
          if args.size > 0
            value = args.pop
            self.is_a?(Module) ? ( @@__index_prefix__ = value ) : ( @__index_prefix__ = value )
          end
          self.is_a?(Module) ? ( @@__index_prefix__ || nil ) : ( @__index_prefix__ || @@__index_prefix__ || nil )
        end
        extend self

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
          @document_type || klass.model_name.to_s.underscore
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
