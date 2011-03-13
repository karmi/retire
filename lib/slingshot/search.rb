module Slingshot
  module Search
  
    class Search

      attr_reader :indices, :url, :results, :response, :query, :facets

      def initialize(*indices, &block)
        @options = indices.pop if indices.last.is_a?(Hash)
        @indices = indices
        raise ArgumentError, 'Please pass index or indices to search' if @indices.empty?
        if @options
          Configuration.wrapper @options[:wrapper] if @options[:wrapper]
        end
        instance_eval(&block) if block_given?
      end

      def query(&block)
        @query = Query.new(&block)
        self
      end

      def sort(&block)
        @sort = Sort.new(&block)
        self
      end

      def facet(name, options={}, &block)
        @facets ||= {}
        @facets.update Facet.new(name, options, &block).to_hash
        self
      end

      def from(value)
        @from = value
        self
      end

      def size(value)
        @size = value
        self
      end

      def fields(fields=[])
        @fields = fields
        self
      end

      def perform
        @url     = "#{Configuration.url}/#{indices.join(',')}/_search"
        @response = JSON.parse( Configuration.client.post(@url, self.to_json) )
        @results = Results::Collection.new(@response)
        self
      rescue Exception
        STDERR.puts "Request failed: \n#{self.to_curl}"
        raise
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
        request.update( { :fields => @fields } ) if @fields
        request.to_json
      end

    end

  end
end
