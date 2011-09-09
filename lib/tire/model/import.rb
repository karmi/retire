module Tire
  module Model

    # Provides support for easy importing of large ActiveRecord- and ActiveModel-bound
    # recordsets into model index.
    #
    # Relies on pagination support in your model, namely the `paginate` class method.
    #
    # Please refer to the relevant of the README for more information.
    #
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
