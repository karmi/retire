module Slingshot
  module Model

    module Persistence

      def self.included(base)

        base.class_eval do
          include ActiveModel::AttributeMethods
          include ActiveModel::Validations
          include ActiveModel::Serialization
          include ActiveModel::Serializers::JSON
          include ActiveModel::Naming

          extend  ActiveModel::Callbacks
          define_model_callbacks :save, :destroy

          extend  ClassMethods
          include InstanceMethods
        end

      end

      module ClassMethods

        def find *args
          # TODO: Options like `sort`
          old_wrapper = Slingshot::Configuration.wrapper
          Slingshot::Configuration.wrapper self
          options = args.pop if args.last.is_a?(Hash)
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

        def mode
          :persistable
        end

        def index_name
          model_name.plural
        end

        def document_type
          model_name.singular
        end

      end

      module InstanceMethods

        attr_reader :attributes

        def initialize(attributes)
          @attributes = attributes
        end

        def id
          attributes['id']
        end

        def save
          _run_save_callbacks do
          end
        end

        def destroy
          _run_destroy_callbacks do
            @destroyed = true
          end
        end

        def destroyed?; !!@destroyed; end

      end

    end

  end
end
