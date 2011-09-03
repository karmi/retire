module Tire
  module Model

    module Naming

      module ClassMethods
        def index_name name=nil
          @index_name = name if name
          @index_name || klass.model_name.plural
        end

        def document_type
          klass.model_name.singular
        end
      end

      module InstanceMethods
        def index_name name=nil
          @index_name = name if name
          @index_name || instance.class.tire.index_name
        end

        def document_type
          instance.class.tire.document_type
        end
      end

    end

  end
end
