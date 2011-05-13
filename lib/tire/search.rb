module Tire
  module Search
  
    class Search

      attr_reader :indices, :url, :results, :response, :json, :query, :facets, :filters, :options

      def initialize(*indices, &block)
        @options = indices.last.is_a?(Hash) ? indices.pop  : {}
        @indices = indices
        raise ArgumentError, 'Please pass index or indices to search' if @indices.empty?
        if @options
          Configuration.wrapper @options[:wrapper] if @options[:wrapper]
        end
        instance_eval(&block) if block_given?
      end

      def query(&block)
        @query = Query.new
        block.arity < 1 ? @query.instance_eval(&block) : block.call(@query)
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

      def highlight(*args)
        unless args.empty?
          @highlight = Highlight.new(*args)
          self
        else
          @highlight
        end
      end

      def from(value)
        @from = value
        @options[:from] = value
        self
      end

      def size(value)
        @size = value
        @options[:size] = value
        self
      end

      def fields(fields=[])
        @fields = fields
        self
      end

      def perform
        @url      = "#{Configuration.url}/#{indices.join(',')}/_search"
        @response = Configuration.client.post(@url, self.to_json)
        @json     = Yajl::Parser.parse(@response.body)
        @results  = Results::Collection.new(@json, @options)
        self
      rescue Exception => error
        STDERR.puts "[REQUEST FAILED] #{self.to_curl}\n"
        raise
      ensure
        logged(error)
      end

      def to_curl
        %Q|curl -X POST "#{Configuration.url}/#{indices.join(',')}/_search?pretty=true" -d '#{self.to_json}'|
      end

      def to_json
        request = {}
        request.update( { :query  => @query } )
        request.update( { :sort   => @sort } )     if @sort
        request.update( { :facets => @facets } )   if @facets
        @filters.each { |filter| request.update( { :filter => filter } ) } if @filters
        request.update( { :highlight => @highlight } ) if @highlight
        request.update( { :size => @size } )       if @size
        request.update( { :from => @from } )       if @from
        request.update( { :fields => @fields } )   if @fields
        Yajl::Encoder.encode(request)
      end

      def logged(error=nil)
        if Configuration.logger

          Configuration.logger.log_request '_search', indices, to_curl

          code = @response ? @response.code : error.message
          took = @json['took'] rescue nil

          if Configuration.logger.level.to_s == 'debug'
            # FIXME: Depends on RestClient implementation
            body = @response ? Yajl::Encoder.encode(@json, :pretty => true) : body = error.http_body
          else
            body = ''
          end

          Configuration.logger.log_response code, took, body
        end
      end

    end

  end
end
