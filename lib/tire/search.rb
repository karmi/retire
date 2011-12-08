module Tire
  module Search
    class SearchRequestFailed < StandardError; end
  
    class Search

      attr_reader :indices, :results, :response, :json, :query, :facets, :filters, :options

      def initialize(indices=nil, options = {}, &block)
        @indices = Array(indices)
        @types   = Array(options.delete(:type))
        @options = options

        @path    = ['/', @indices.join(','), @types.join(','), '_search'].compact.join('/').squeeze('/')

        block.arity < 1 ? instance_eval(&block) : block.call(self) if block_given?
      end

      def url
        Configuration.url + @path
      end

      def query(&block)
        @query = Query.new
        block.arity < 1 ? @query.instance_eval(&block) : block.call(@query)
        self
      end

      def sort(&block)
        @sort = Sort.new(&block).to_ary
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

      def fields(*fields)
        @fields = Array(fields.flatten)
        self
      end

      def perform
        @response = Configuration.client.get(self.url, self.to_json)
        if @response.failure?
          STDERR.puts "[REQUEST FAILED] #{self.to_curl}\n"
          raise SearchRequestFailed, @response.to_s
        end
        @json     = MultiJson.decode(@response.body)
        @results  = Results::Collection.new(@json, @options)
        return self
      ensure
        logged
      end

      def to_curl
        %Q|curl -X GET "#{self.url}?pretty=true" -d '#{self.to_json}'|
      end

      def to_hash
        request = {}
        request.update( { :query  => @query.to_hash } )    if @query
        request.update( { :sort   => @sort.to_ary   } )    if @sort
        request.update( { :facets => @facets.to_hash } )   if @facets
        request.update( { :filter => @filters.first.to_hash } ) if @filters && @filters.size == 1
        request.update( { :filter => { :and => @filters.map { |filter| filter.to_hash } } } ) if  @filters && @filters.size > 1
        request.update( { :highlight => @highlight.to_hash } ) if @highlight
        request.update( { :size => @size } )               if @size
        request.update( { :from => @from } )               if @from
        request.update( { :fields => @fields } )           if @fields
        request
      end

      def to_json
        to_hash.to_json
      end

      def logged(error=nil)
        if Configuration.logger

          Configuration.logger.log_request '_search', indices, to_curl

          took = @json['took']  rescue nil
          code = @response.code rescue nil

          if Configuration.logger.level.to_s == 'debug'
            # FIXME: Depends on RestClient implementation
            body = if @json
              defined?(Yajl) ? Yajl::Encoder.encode(@json, :pretty => true) : MultiJson.encode(@json)
            else
              @response.body rescue nil
            end
          else
            body = ''
          end

          Configuration.logger.log_response code || 'N/A', took || 'N/A', body || 'N/A'
        end
      end

    end

  end
end
