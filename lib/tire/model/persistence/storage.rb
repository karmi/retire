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
            if result = document.save
              document
            else
              result
            end
          end

          def delete(&block)
            DeleteByQuery.new(index_name, {:type => document_type}, &block).perform
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
                response = index.remove self
              else
                if response = index.store( self, {:percolate => percolator} )
                  self.id     ||= response['_id']
                  self._index   = response['_index']
                  self._type    = response['_type']
                  self._version = response['_version']
                  self.matches  = response['matches']
                end
              end
              response
            end
          end

          def save
            return false unless valid?
            run_callbacks :save do
              response = update_index
              !! response['ok']
            end
          end

          def destroy
            run_callbacks :destroy do
              @destroyed = true
              response = update_index
              ! response.nil?
            end
          end

          def destroyed?   ;  !!@destroyed;       end
          def persisted?   ;  !!id && !!_version; end
          def new_record?  ;  !persisted?;        end
        end
      end

    end

  end
end
