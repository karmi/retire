module Tire
  module Model

    module Persistence

      # Provides infrastructure for an _ActiveRecord_-like interface for finding records.
      #
      module Finders

        module ClassMethods

          def find *args
            # TODO: Options like `sort`
            old_wrapper = Tire::Configuration.wrapper
            Tire::Configuration.wrapper self
            options = args.pop if args.last.is_a?(Hash)
            args.flatten!
            if args.size > 1
              Tire::Search::Search.new(index.name).query do |query|
                query.ids(args, document_type)
              end.perform.results
            else
              case args = args.pop
                when Fixnum, String
                  Index.new(index_name).retrieve document_type, args
                when :all, :first
                  send(args)
                else
                  raise ArgumentError, "Please pass either ID as Fixnum or String, or :all, :first as an argument"
              end
            end
          ensure
            Tire::Configuration.wrapper old_wrapper
          end

          def all
            # TODO: Options like `sort`; Possibly `filters`
            old_wrapper = Tire::Configuration.wrapper
            Tire::Configuration.wrapper self
            s = Tire::Search::Search.new(index_name).query { all }
            s.perform.results
          ensure
            Tire::Configuration.wrapper old_wrapper
          end

          def first
            # TODO: Options like `sort`; Possibly `filters`
            old_wrapper = Tire::Configuration.wrapper
            Tire::Configuration.wrapper self
            s = Tire::Search::Search.new(index_name).query { all }.size(1)
            s.perform.results.first
          ensure
            Tire::Configuration.wrapper old_wrapper
          end

        end

      end

    end

  end
end
