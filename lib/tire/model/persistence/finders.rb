module Tire
  module Model

    module Persistence

      # Provides infrastructure for an _ActiveRecord_-like interface for finding records.
      #
      module Finders

        module ClassMethods

          def find *args
            # TODO: Options like `sort`
            options = args.pop if args.last.is_a?(Hash)
            args.flatten!
            if args.size > 1
              Tire::Search::Search.new(index.name, :wrapper => self) do |search|
                search.query do |query|
                  query.ids(args, document_type)
                end
                search.size args.size
              end.results
            else
              case args = args.pop
                when Fixnum, String
                  index.retrieve document_type, args, :wrapper => self
                when :all, :first
                  send(args)
                else
                  raise ArgumentError, "Please pass either ID as Fixnum or String, or :all, :first as an argument"
              end
            end
          end

          def all
            # TODO: Options like `sort`; Possibly `filters`
            s = Tire::Search::Search.new(index.name, :type => document_type, :wrapper => self).query { all }
            s.version(true).results
          end

          def first
            # TODO: Options like `sort`; Possibly `filters`
            s = Tire::Search::Search.new(index.name, :type => document_type, :wrapper => self).query { all }.size(1)
            s.version(true).results.first
          end

        end

      end

    end

  end
end
