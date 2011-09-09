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
          if name && name.is_a?(Proc)
            # We want to dynamically create the index name
            @index_name = name
          else
            @index_name = name if name
            @index_name || [index_prefix, klass.model_name.plural].compact.join('_')
          end
        end

        # Returns +true+ if index name is dynamically generated.
        def dynamic_index_name?
          index_name.is_a?(Proc)
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
          @document_type || klass.model_name.singular
        end
      end

      module InstanceMethods

        # Proxy to class method `index_name`.
        #
        def index_name
          if instance.class.dynamic_index_name?
            # Return the dynamically generated index name
            block = instance.class.tire.index_name
            block.arity > 0 ? block.call(instance) : block.call
          else
            instance.class.tire.index_name
          end
        end

        # Returns +true+ if index name is dynamically generated.
        def dynamic_index_name?
          instance.class.dynamic_index_name?
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
