module Slingshot
  module Model

    module Mapping

      module ClassMethods

        def mapping
          if block_given?
            yield
            create_index_or_update_mapping
          else
            @mapping ||= {}
          end
        end

        private

        def create_index_or_update_mapping
          unless index.exists?
            index.create :mappings => mapping_to_hash
          else
            # TODO: Update mapping
          end
        rescue Exception => e
          # TODO: STDERR + logger
          raise
        end

        def mapping_to_hash
          { document_type.to_sym => { :properties => mapping } }
        end

      end

    end

  end
end
