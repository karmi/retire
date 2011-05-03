module Tire
  module Model

    module Import

      module ClassMethods

        def import options={}, &block
          method = options.delete(:method) || 'paginate'
          self.elasticsearch_index.import self, method, options, &block
        end

      end

    end

  end
end
