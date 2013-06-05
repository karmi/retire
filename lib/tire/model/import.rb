module Tire
  module Model

    # Provides support for efficient and effective importing of large recordsets into Elasticsearch.
    #
    # Tire will use dedicated strategies for fetching records in batches when ActiveRecord or Mongoid models are detected.
    #
    # Two dedicated strategies for popular pagination libraries are also provided: WillPaginate and Kaminari.
    # These could be used in situations where your model is neither ActiveRecord nor Mongoid based.
    #
    # You can implement your own custom strategy and pass it via the `:strategy` option.
    #
    # Note, that it's always possible to use the `Tire::Index#import` method directly.
    #
    # @note See `Tire::Import::Strategy`.
    #
    module Import

      module ClassMethods
        def import options={}, &block
          strategy = Strategy.from_class(klass, options)
          strategy.import &block
        end
      end

      # Importing strategies for common persistence frameworks (ActiveModel, Mongoid), as well as
      # pagination libraries (WillPaginate, Kaminari), or a custom strategy.
      #
      module Strategy
        def self.from_class(klass, options={})
          return const_get(options[:strategy]).new(klass, options) if options[:strategy]

          case
          when defined?(::ActiveRecord) && klass.ancestors.include?(::ActiveRecord::Base)
            ActiveRecord.new klass, options
          when defined?(::Mongoid::Document) && klass.ancestors.include?(::Mongoid::Document)
            Mongoid.new klass, options
          when defined?(Kaminari) && klass.respond_to?(:page)
            Kaminari.new klass, options
          when defined?(WillPaginate) && klass.respond_to?(:paginate)
            WillPaginate.new klass, options
          else
            Default.new klass, options
          end
        end

        module Base
          attr_reader :klass, :options, :index
          def initialize(klass, options={})
            @klass   = klass
            @options = {:per_page => 1000}.update(options)
            @index   = options[:index] ? Tire::Index.new(options.delete(:index)) : klass.tire.index
          end
        end

        class ActiveRecord
          include Base
          def import &block
            klass.find_in_batches(:batch_size => options[:per_page]) do |batch|
              index.import batch, options, &block
            end
            self
          end
        end

        class Mongoid
          include Base
          def import &block
            items = []
            klass.all.each do |item|
              items << item
              if items.length % options[:per_page] == 0
                index.import items, options, &block
                items = []
              end
            end
            index.import items, options, &block unless items.empty?
            self
          end
        end

        class Kaminari
          include Base
          def import &block
            current = 0
            page = 1
            while current < klass.count
              items = klass.page(page).per(options[:per_page])
              index.import items, options, &block
              current = current + items.size
              page += 1
            end
            self
          end
        end

        class WillPaginate
          include Base
          def import &block
            current = 0
            page = 1
            while current < klass.count
              items = klass.paginate(:page => page, :per_page => options[:per_page])
              index.import items, options, &block
              current += items.size
              page += 1
            end
            self
          end
        end

        class Default
          include Base
          def import &block
            index.import klass, options.update(:method => 'paginate'), &block
            self
          end
        end
      end

    end
  end
end
