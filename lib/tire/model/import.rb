
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
          if klass.respond_to? :find_in_batches
            klass.tire.index_scope.find_in_batches do |group|
              index.import group, options, &block
              GC.start
            end
          else
            index.import klass.index_scope, options, &block
          end
        end

      end

    end

  end
end
