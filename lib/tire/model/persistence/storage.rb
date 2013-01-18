module Tire
  module Model

    module Persistence

      # Provides infrastructure for storing records in _Elasticsearch_.
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

          def update_index
            run_callbacks :update_elasticsearch_index do
              if destroyed?
                index.remove self
              else
                response  = index.store( self, {:percolate => percolator} )
                self.id     ||= response['_id']
                self._index   = response['_index']
                self._type    = response['_type']
                self._version = response['_version']
                self.matches  = response['matches']
                self
              end
            end
          end

          def save
            return false unless valid?
            run_callbacks :save do
              update_index
            end
            self
          end

          def destroy
            run_callbacks :destroy do
              @destroyed = true
              update_index
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
