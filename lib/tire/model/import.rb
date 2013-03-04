
module Tire
  module Model

    # Provides support for easy importing of large ActiveRecord- and ActiveModel-bound
    # recordsets into model index.
    #
    # Relies on pagination support in your model, namely the `paginate` class method.
    #
    # Please refer to the relevant of the README for more information.
    #
    module Import

      module ClassMethods

        def import options = {}, &block
          options[:per_page] ||= 1000

          # Lets support multiple ORM's
          if defined?(ActiveRecord) && klass.ancestors.include?(::ActiveRecord::Base) # Active Record
            extend ActiveRecord
          elsif defined?(Mondgoid::Document) && klass.ancestors.include?(::Mongoid::Document) # Mongoid
            extend Mongoid
          elsif defined?(Kaminari) && klass.respond_to?(:page) # Kaminari
            extend Kaminari
          elsif defined?(WillPaginate) && klass.respond_to?(:paginate)  # Will Paginate
            extend WillPaginate
          else
            extend Index
          end

          import options, &block

        end

      end

      module ActiveRecord
        def import options={}, &block
          index   = options[:index] ? Tire::Index.new(options.delete(:index)) : klass.tire.index
          klass.find_in_batches(batch_size: options[:per_page]) do |group|
            index.import group, options, &block
          end
        end
      end

      module Mongoid
        def import options={}, &block
          index   = options[:index] ? Tire::Index.new(options.delete(:index)) : klass.tire.index
          0.step(klass.count, options[:per_page]) do |offset|
            items = klass.limit(options[:per_page]).skip(offset)
            index.import items, options, &block
          end
        end
      end

      module Kaminari
        def import options={}, &block
          index   = options[:index] ? Tire::Index.new(options.delete(:index)) : klass.tire.index
          current = 0
          page = 1
          while current < klass.count
            items = klass.page(page).per(options[:per_page])
            index.import items, options, &block
            current = current + items.size
            page += 1
          end
        end
      end

      module WillPaginate
        def import options={}, &block
          index   = options[:index] ? Tire::Index.new(options.delete(:index)) : klass.tire.index
          current = 0
          page = 1
          while current < klass.count
            items = klass.paginate(page: page, per_page: options[:per_page])
            index.import items, options, &block
            current += items.size
            page += 1
          end
        end
      end

      module Index
        def import options={}, &block
          index   = options[:index] ? Tire::Index.new(options.delete(:index)) : klass.tire.index
          index.import klass, options, &block
        end
      end

    end
  end
end
