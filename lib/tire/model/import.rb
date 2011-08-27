module Tire
  module Model

    module Import

      module ClassMethods

        def import options={}, &block
          method = options.delete(:method) || 'paginate'
          index.import klass, method, options, &block
        end

      end

    end

  end
end
