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
          # You can pass mapping definition for Elasticsearch in the options Hash.
          #
          # You can define default property values.
          #
          def property(name, options = {})

            # Define attribute reader:
            define_method("#{name}") do
              instance_variable_get(:"@#{name}")
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
            unless (default_value = options.delete(:default)).nil?
              property_defaults[name.to_sym] = default_value.respond_to?(:call) ? default_value.call : default_value
            end

            # Save property casting (when relevant):
            property_types[name.to_sym] = options[:class] if options[:class]

            # Define default value for colletions:
            if options[:class].is_a?(Array)
              property_defaults[name.to_sym] ||= []
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

          def property_types
            @property_types ||= {}
          end

          private

          def define_query_method name
            define_method("#{name}?")  { !! send(name) }
          end

        end

        module InstanceMethods

          attr_accessor :id

          def initialize(attributes={})
            # Make a copy of objects in the property defaults hash, so default values
            # such as `[]` or `{ foo: [] }` are preserved.
            #
            property_defaults = self.class.property_defaults.inject({}) do |hash, item|
              key, value = item
              hash[key.to_sym] = value.class.respond_to?(:new) ? value.clone : value
              hash
            end
            __update_attributes(property_defaults.merge(attributes))
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

          def __update_attributes(attributes)
            attributes.each { |name, value| send "#{name}=", __cast_value(name, value) }
          end

          # Casts the values according to the <tt>:class</tt> option set when
          # defining the property, cast Hashes as Hashr[http://rubygems.org/gems/hashr]
          # instances and automatically convert UTC formatted strings to Time.
          #
          def __cast_value(name, value)
            case

              when klass = self.class.property_types[name.to_sym]
                if klass.is_a?(Array) && value.is_a?(Array)
                  value.map { |v| klass.first.new(v) }
                else
                  klass.new(value)
                end

              when value.is_a?(Hash)
                Hashr.new(value)

              else
                # Strings formatted as <http://en.wikipedia.org/wiki/ISO8601> are automatically converted to Time
                value = Time.parse(value).utc if value.is_a?(String) && value =~ /^\d{4}[\/\-]\d{2}[\/\-]\d{2}T\d{2}\:\d{2}\:\d{2}/
                value
            end
          end

        end

      end

    end
  end
end
