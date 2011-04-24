module Slingshot
  module Model

    module Persistence

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
            response    = document.update_elastic_search_index
            document.id = response['_id']
            document
          end

          def index
            @index ||= Index.new(index_name)
          end

        end

        module InstanceMethods

          def update_attribute(name, value)
            send("#{name}=", value)
            save
          end

          def update_attributes(attributes={})
            attributes.each do |name, value|
              send("#{name}=", value)
            end
            save
          end

          def save
            return false unless valid?
            run_callbacks :save do
            end
            self
          end

          def destroy
            run_callbacks :destroy do
              @destroyed = true
            end
            self.freeze
          end

          def destroyed?; !!@destroyed; end

          def persisted?; !!id;           end

        end

      end

    end

  end
end
