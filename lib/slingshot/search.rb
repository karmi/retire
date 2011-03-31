module Slingshot
  module Search
  
    class Search

      attr_reader :indices, :url, :results, :response, :json, :query, :facets, :filters

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

      def filter(type, *options)
        @filters ||= []
        @filters << Filter.new(type, *options).to_hash
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
        @url      = "#{Configuration.url}/#{indices.join(',')}/_search"
        @response = Configuration.client.post(@url, self.to_json)
        @json     = Yajl::Parser.parse(@response)
        @results  = Results::Collection.new(@json)
        self
      rescue Exception
        STDERR.puts "[REQUEST FAILED]\n#{self.to_curl}\n"
        raise
      ensure
        if Configuration.logger
          Configuration.logger.log_request  '_search', indices, to_curl
          if Configuration.logger.level == 'debug'
            Configuration.logger.log_response @response.code, Yajl::Encoder.encode(@json, :pretty => true)
          end
        end
      end

      def to_curl
        %Q|curl -X POST "#{Configuration.url}/#{indices}/_search?pretty=true" -d '#{self.to_json}'|
      end

      def to_json
        request = {}
        request.update( { :query  => @query } )
        request.update( { :sort   => @sort } )     if @sort
        request.update( { :facets => @facets } )   if @facets
        @filters.each { |filter| request.update( { :filter => filter } ) } if @filters
        request.update( { :size => @size } )       if @size
        request.update( { :from => @from } )       if @from
        request.update( { :fields => @fields } )   if @fields
        Yajl::Encoder.encode(request)
      end

    end

  end
end
