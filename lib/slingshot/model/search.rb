module Slingshot
  module Model

    module Search

      def self.included(base)
        base.send :extend, ClassMethods
      end

      module ClassMethods

        def search(query=nil, options={}, &block)
          old_wrapper = Slingshot::Configuration.wrapper
          Slingshot::Configuration.wrapper self
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
            s.perform.results
          else
            s = Slingshot::Search::Search.new(index, options, &block).perform.results
          end
        ensure
          Slingshot::Configuration.wrapper old_wrapper
        end

      end


      extend ClassMethods
    end

  end
end
