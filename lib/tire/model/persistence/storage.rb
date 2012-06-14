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
            document = new(args)
            document.save
          end

          def create!(args={})
            document = new(args)
            document.save!
          end

        end

        module InstanceMethods

          def update_attribute!(name, value)
            update_attributes! name => value
          end

          def update_attribute(name, value)
            update_attributes name => value
          end

          def update_attributes!(attributes={})
            self.attributes = attributes
            save!
          end

          def update_attributes(attributes={})
            self.attributes = attributes
            save
          end

          def save!
            raise Tire::DocumentNotValid.new(self) unless valid?

            run_callbacks :save do
              # Document#id is set in the +update_elasticsearch_index+ method,
              # where we have access to the JSON response
            end

            self
          end

          def save
            begin
              save!
            rescue Tire::DocumentNotValid, Tire::RequestError
              false
            end
          end

          def destroy
            run_callbacks :destroy do
              @destroyed = true
            end
            self.freeze
          end

          def destroyed?   ;  !!@destroyed;       end
          def persisted?   ;  !!id && !!_version; end
          def new_record?  ;  !persisted?;        end

        end

      end

    end

  end
end
