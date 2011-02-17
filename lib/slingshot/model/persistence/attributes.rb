module Slingshot
  module Model

    module Persistence

      module Attributes

        module InstanceMethods

          attr_reader :attributes

          def initialize(attributes)
            @attributes = attributes
          end

          def id
            attributes['id']
          end

        end

      end

    end
  end
end
