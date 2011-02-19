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
            attributes[:id] || attributes['id']
          end

          def persisted?
            !!id
          end

          def method_missing(method_id, *arguments, &block)
            method_id    = method_id.to_sym    # Let's be as defensive as a motherfucking Tony Montana here.
            method_name  = method_id.to_s
            query_method = method_name.gsub(/\?$/, '')
            case
              when has_attribute?(method_id)                                          # Getter (+name+)
                attributes[method_id] || attributes[method_name]
              when has_attribute?(query_method)                                              # Attribute query (<tt>admin?</tt>)
                !!attributes[query_method.to_sym] || !!attributes[query_method.to_s]
              when method_name =~ /=$/                                                # Setter (<tt>name=value</tt>)
                attributes.store method_name.gsub(/=$/, '').to_sym, arguments.shift
              else
                super
            end
          end

          def respond_to?(method)
            return true if super || attribute_method?(method)
            super
          end

          def attribute_names
            attributes.keys.map { |a| a.to_s }
          end

          def has_attribute?(name)
            attributes.has_key?(name.to_sym) || attributes.has_key?(name.to_s)
          end

          protected

          def attribute_method?(attr_name)
            attribute_names.include?(attr_name.to_s)
          end

          private

          def id=(value)
            attributes[:id] = value
            self
          end

        end

      end

    end
  end
end
