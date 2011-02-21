module Slingshot
  module Model

    module Persistence

      module Attributes

        module InstanceMethods

          def initialize(attributes={})
            attributes.each { |name, value| send("#{name}=", value) }
          end

          def attributes
            @attributes ||= {}
          end

          def id
            attributes['_id'] || attributes['id']
          end

          def persisted?
            !!id
          end

          def method_missing(method_id, *arguments, &block)
            method_id    = method_id.to_sym    # Let's be as defensive as a motherfucking Tony Montana here.
            method_name  = method_id.to_s
            query_method = method_name.gsub(/\?$/, '')
            case
              when has_attribute?(method_id)                                              # Getter (+name+)
                attributes[method_id] || attributes[method_name]
              when has_attribute?(query_method)                                           # Attribute query (<tt>admin?</tt>)
                !!attributes[query_method.to_sym] || !!attributes[query_method.to_s]
              when method_name =~ /=$/                                                    # Setter (<tt>name=value</tt>)
                # NOTE: Beware of `comparison of String with :last_name failed` in `attributes.keys.sort` (ActiveModel)
                attributes.store method_name.gsub(/=$/, '').to_s, arguments.shift
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
            attributes['id'] = value
            self
          end

        end

      end

    end
  end
end
