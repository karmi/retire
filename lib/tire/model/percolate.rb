module Tire
  module Model

    module Percolate

      module ClassMethods
        def percolate!(pattern=true)
          @@_percolator = pattern
          self
        end

        def on_percolate(pattern=true,&block)
          self.percolate!(pattern)
          after_update_elastic_search_index(block)
        end

        def percolator
          defined?(@@_percolator) ? @@_percolator : nil
        end
      end

      module InstanceMethods

        def percolate(&block)
          index.percolate document_type, self, block
        end

        def percolate=(pattern)
          @_percolator = pattern
        end

        def percolator
          @_percolator || self.class.percolator || nil
        end
      end

    end

  end
end
