module Tire
  module Model

    module Persistence

      # Provides infrastructure for storing records in _ElasticSearch_.
      #
      module Storage

        def self.included(base)

          base.class_eval do
            extend  ClassMethods
            include InstanceMethods            
          end

        end

        module ClassMethods

          def create(args={})
            document    = new(args)
            return false unless document.valid?
            document.save
            document
          end

        end

        module InstanceMethods

          def update_attribute(name, value)
            __update_attributes name => value
            save
          end

          def update_attributes(attributes={})
            __update_attributes attributes
            save
          end

          def save
            return false unless valid?
            run_callbacks :save do
              # Document#id is set in the +update_elasticsearch_index+ method,
              # where we have access to the JSON response
            end
            self
          end

          def destroy
            run_callbacks :destroy do
              @destroyed = true
            end
            self.freeze
          end

          # TODO: Implement `new_record?` and clean up

          def destroyed?; !!@destroyed; end

          def persisted?; !!id;           end

        end

      end

    end

  end
end
