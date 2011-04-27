module Slingshot
  module Model

    module Import

      module ClassMethods

        def import options={}
          raise NoMethodError,
                "Class '#{self}' must have `paginate` class method (provided eg. by the will_paginate gem) for importing." \
                 unless respond_to?(:paginate)

          options = {:page => 1, :per_page => 1000}.merge options

          while documents = paginate(options.merge :page => options[:page]) and not documents.empty?
            documents = yield documents if block_given?

            index.bulk_store documents
            options[:page] += 1
          end
        end

      end

    end

  end
end
