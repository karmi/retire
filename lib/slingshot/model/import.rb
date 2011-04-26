module Slingshot
  module Model

    module Import

      module ClassMethods

        def import options={}
          raise NoMethodError,
                "Class '#{self}' must have `paginate` class method (provided eg. by the will_paginate gem) for importing." \
                 unless respond_to?(:paginate)

          options = {:page => 1, :per_page => 1000}.update options
          page    = options[:page]

          while documents = paginate(options.merge :page => page) and not documents.empty?
            print '.'
            index.bulk_store documents
            page += 1
          end
        end

      end

    end

  end
end
