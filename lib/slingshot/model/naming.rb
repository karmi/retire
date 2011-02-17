module Slingshot
  module Model

    module Naming

      module ClassMethods
        def index_name
          model_name.plural
        end

        def document_type
          model_name.singular
        end
      end

      module InstanceMethods
        def index_name
          self.class.index_name
        end

        def document_type
          self.class.document_type
        end
      end

    end

  end
end
