
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
          options = { :method => 'paginate' }.update options
          index   = options[:index] ? Tire::Index.new(options.delete(:index)) : self.index
          index.import klass, options, &block
        end

      end

    end

  end
end
