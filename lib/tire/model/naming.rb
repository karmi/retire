module Tire
  module Model

    module Naming

      module ClassMethods
        def index_name name=nil
          if name && name.is_a?(Proc)
            # We want to dynamically create the index name
            @index_name = name
          else
            @index_name = name if name
            @index_name || klass.model_name.plural
          end
        end

        # Returns +true+ if index name is dynamically generated.
        def dynamic_index_name?
          index_name.is_a?(Proc)
        end

        def document_type
          klass.model_name.singular
        end
      end

      module InstanceMethods
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

        def document_type
          instance.class.tire.document_type
        end
      end

    end

  end
end
