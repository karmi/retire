module Slingshot
  module Search
  
    class Search

      attr_reader :indices, :url, :results, :query, :facets

      def initialize(*indices, &block)
        raise ArgumentError, 'Please pass index or indices to search' if indices.empty?
        @indices = indices
        instance_eval(&block) if block_given?
      end

      def query(&block)
        @query = Query.new(&block)
      end

      def sort(&block)
        @sort = Sort.new(&block)
      end

      def facet(name, &block)
        @facets ||= {}
        @facets.update Facet.new(name, &block).to_hash
      end

      def from(value)
        @from = value
      end

      def size(value)
        @size = value
      end

      def perform
        @url     = "#{Configuration.url}/#{indices.join(',')}/_search"
        response = JSON.parse( Configuration.client.post(@url, self.to_json) )
        @results = Results::Collection.new(response)
      end

      def to_curl
        %Q|curl -X POST "http://localhost:9200/#{indices}/_search?pretty=true" -d '#{self.to_json}'|
      end

      def to_json
        request = {}
        request.update( { :query  => @query } )
        request.update( { :sort   => @sort } )   if @sort
        request.update( { :facets => @facets } ) if @facets
        request.update( { :size => @size } )     if @size
        request.update( { :from => @from } )     if @from
        request.to_json
      end

    end

  end
end
