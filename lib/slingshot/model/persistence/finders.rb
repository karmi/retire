module Slingshot
  module Model

    module Persistence

      module Finders

        module ClassMethods

          def find *args
            # TODO: Options like `sort`
            old_wrapper = Slingshot::Configuration.wrapper
            Slingshot::Configuration.wrapper self
            options = args.pop if args.last.is_a?(Hash)
            args.flatten!
            if args.size > 1
              Slingshot::Search::Search.new(index_name).query { terms :_id, args }.perform.results
            else
              case args = args.pop
                when Fixnum, String
                  Index.new(index_name).retrieve document_type, args
                when :all, :first, :last
                  send(args)
                else
                  raise ArgumentError, "Please pass either ID as Fixnum or String, or :all, :first, :last as an argument"
              end
            end
          ensure
            Slingshot::Configuration.wrapper old_wrapper
          end

          def all
            # TODO: Options like `sort`; Possibly `filters`
            old_wrapper = Slingshot::Configuration.wrapper
            Slingshot::Configuration.wrapper self
            s = Slingshot::Search::Search.new(index_name).query { all }
            s.perform.results
          ensure
            Slingshot::Configuration.wrapper old_wrapper
          end

          def first
            # TODO: Options like `sort`; Possibly `filters`
            old_wrapper = Slingshot::Configuration.wrapper
            Slingshot::Configuration.wrapper self
            s = Slingshot::Search::Search.new(index_name).query { all }.size(1)
            s.perform.results
          ensure
            Slingshot::Configuration.wrapper old_wrapper
          end

        end

      end

    end

  end
end
