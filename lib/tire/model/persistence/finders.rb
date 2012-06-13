module Tire
  module Model

    module Persistence

      # Provides infrastructure for an _ActiveRecord_-like interface for finding records.
      #
      module Finders

        module ClassMethods

          def find *args
            # TODO: Options like `sort`
            default_options = {:wrapper => self}

            options = args.last.is_a?(Hash) ? args.pop : {}
            options = default_options.update(options)

            args.flatten!
            if args.size > 1
              Tire::Search::Search.new(index.name, options) do |search|
                search.query do |query|
                  query.ids(args, document_type)
                end
                search.size args.size
              end.results
            else
              case args = args.pop
                when Fixnum, String
                  index.retrieve document_type, args, options
                when :all, :first
                  send(args)
                else
                  raise ArgumentError, "Please pass either ID as Fixnum or String, or :all, :first as an argument"
              end
            end
          end

          def all options={}
            # TODO: Options like `sort`; Possibly `filters`
            default_options = {:wrapper => self}
            options = default_options.update(options)

            s = Tire::Search::Search.new(index.name, options).query { all }
            s.results
          end

          def first options={}
            # TODO: Options like `sort`; Possibly `filters`
            default_options = {:wrapper => self}
            options = default_options.update(options)

            s = Tire::Search::Search.new(index.name, options).query { all }.size(1)
            s.results.first
          end

        end

      end

    end

  end
end
