module Slingshot
  module Search
  
    class Search

      attr_reader :indices

      def initialize(*indices, &block)
        raise ArgumentError, 'Please pass index or indices to search' if indices.empty?
        @indices = indices
        instance_eval(&block) if block_given?
      end

      def query(&block)
        @query = Query.new
        @query.instance_eval(&block)
        @query
      end

      def to_json
        request = { :query => @query }
        request.to_json
      end

    end

  end
end
