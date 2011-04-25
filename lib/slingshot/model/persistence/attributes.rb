module Slingshot
  module Model

    module Persistence

      module Attributes

        module ClassMethods

          def property(name, opts = {})
            attr_accessor name.to_sym
            properties << name.to_s unless properties.include?(name.to_s)
            define_query_method      name.to_sym
            define_attribute_methods [name.to_sym]
            # TODO: Mapping
            self
          end

          def properties
            @properties ||= []
          end

          private

          def define_query_method name
            define_method("#{name}?")  { !! send(name) }
          end

        end

        module InstanceMethods

          attr_accessor :id

          def initialize(attributes={})
            attributes.each { |name, value| send("#{name}=", value) }
          end

          def attributes
            self.class.properties.
              inject( self.id ? {'id' => self.id} : {} ) {|attributes, key| attributes[key] = send(key); attributes}
          end

          def attribute_names
            self.class.properties.sort
          end

          def has_attribute?(name)
            properties.include?(name.to_s)
          end
          alias :has_property? :has_attribute?

        end

      end

    end
  end
end
