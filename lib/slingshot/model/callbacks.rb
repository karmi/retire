module Slingshot
  module Model

    module Callbacks

      def self.included(base)
        if base.respond_to?(:after_save) && base.respond_to?(:after_destroy)
          base.send :after_save,    :update_elastic_search_index
          base.send :after_destroy, :update_elastic_search_index
        end
      end

    end

  end
end
