module Tire
  module Model

    module Percolate

      module ClassMethods
        def percolate!(pattern=true)
          @@_percolator = pattern
          self
        end

        def on_percolate(pattern=true,&block)
          percolate!(pattern)
          klass.after_update_elasticsearch_index(block)
        end

        def percolator
          defined?(@@_percolator) ? @@_percolator : nil
        end
      end

      module InstanceMethods

        def percolate(&block)
          index.percolate instance, block
        end

        def percolate=(pattern)
          @_percolator = pattern
        end

        def percolator
          @_percolator || instance.class.tire.percolator || nil
        end
      end

    end

  end
end
