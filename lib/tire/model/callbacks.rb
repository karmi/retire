module Tire
  module Model

    module Callbacks

      def self.included(base)
        if base.respond_to?(:after_save) && base.respond_to?(:after_destroy)
          base.send :after_save,    lambda { tire.update_index }
          base.send :after_destroy, lambda { tire.update_index }
        end

        if base.respond_to?(:before_destroy) && !base.instance_methods.map(&:to_sym).include?(:destroyed?)
          base.class_eval do
            before_destroy  { @destroyed = true }
            def destroyed?; !!@destroyed; end
          end
        end

        base.class_eval do
          define_model_callbacks(:update_elasticsearch_index, :only => [:after, :before])
        end if base.respond_to?(:define_model_callbacks)
      end

    end

  end
end
