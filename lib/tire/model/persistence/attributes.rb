module Tire
  module Model

    module Persistence

      # Provides infrastructure for declaring the model properties and accessing them.
      #
      module Attributes

        module ClassMethods

          # Define property of the model:
          #
          #    class Article
          #      include Tire::Model::Persistence
          #
          #      property :title,     :analyzer => 'snowball'
          #      property :published, :type => 'date'
          #      property :tags,      :analyzer => 'keywords', :default => []
          #    end
          #
          # You can pass mapping definition for ElasticSearch in the options Hash.
          #
          # You can define default property values.
          #
          def property(name, options = {})

            # Define attribute reader:
            define_method("#{name}") do
              instance_variable_get(:"@#{name}") || self.class.property_defaults[name.to_sym]
            end

            # Define attribute writer:
            define_method("#{name}=") do |value|
              instance_variable_set(:"@#{name}", value)
            end

            # Save the property in properties array:
            properties << name.to_s unless properties.include?(name.to_s)

            # Define convenience <NAME>? method:
            define_query_method      name.to_sym

            # ActiveModel compatibility. NEEDED?
            define_attribute_methods [name.to_sym]

            # Save property default value (when relevant):
            if default_value = options.delete(:default)
              property_defaults[name.to_sym] = default_value
            end

            # Store mapping for the property:
            mapping[name] = options
            self
          end

          def properties
            @properties ||= []
          end

          def property_defaults
            @property_defaults ||= {}
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
