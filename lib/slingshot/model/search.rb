module Slingshot
  module Model

    module Search

      def self.included(base)
        base.send :extend, ClassMethods
      end

      module ClassMethods

        def search(query=nil, options={}, &block)
          index = model_name.plural
          unless block_given?
            Slingshot::Search::Search.new(index, options).query { string query }.perform
          else
            Slingshot::Search::Search.new(index, options, &block).perform
          end
        end

      end


      extend ClassMethods
    end

  end
end
