module Slingshot
  module Model

    module Search

      def self.included(base)
        base.send :extend, ClassMethods
      end

      module ClassMethods

        def search(query=nil, options={}, &block)
          index = model_name.plural
          sort  = options[:order] || options[:sort]
          sort  = Array(sort)
          unless block_given?
            s = Slingshot::Search::Search.new(index, options)
            s.query { string query }
            s.sort do
              sort.each do |t|
                field_name, direction = t.split(' ')
                field_name.include?('.') ? field(field_name, direction) : send(field_name, direction)
              end
            end unless sort.empty?
            s.perform
          else
            Slingshot::Search::Search.new(index, options, &block).perform
          end
        end

      end


      extend ClassMethods
    end

  end
end
