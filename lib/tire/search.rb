module Tire
  module Search
  
    class Search

      attr_reader :indices, :url, :results, :response, :json, :query, :facets, :filters, :options

      def initialize(indices=nil, options = {}, &block)
        @indices = Array(indices)
        @options = options
        @type    = @options[:type]

        @url     = Configuration.url+['/', @indices.join(','), @type, '_search'].compact.join('/').squeeze('/')

        # TODO: Do not allow changing the wrapper here or set it back after yield
        Configuration.wrapper @options[:wrapper] if @options[:wrapper]
        block.arity < 1 ? instance_eval(&block) : block.call(self) if block_given?
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
        @response = Configuration.client.get(@url, self.to_json)
        if @response.failure?
          STDERR.puts "[REQUEST FAILED] #{self.to_curl}\n"
          return false
        end
        @json     = MultiJson.decode(@response.body)
        @results  = Results::Collection.new(@json, @options)
        return self
      ensure
        logged
      end

      def to_curl
        %Q|curl -X GET "#{@url}?pretty=true" -d '#{self.to_json}'|
      end

      def to_hash
        request = {}
        request.update( { :query  => @query.to_hash } )    if @query
        request.update( { :sort   => @sort.to_ary   } )    if @sort
        request.update( { :facets => @facets.to_hash } )   if @facets
        @filters.each { |filter| request.update( { :filter => filter.to_hash } ) } if @filters
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

          took = @json['took'] rescue nil

          if Configuration.logger.level.to_s == 'debug'
            # FIXME: Depends on RestClient implementation
            body = if @json
              defined?(Yajl) ? Yajl::Encoder.encode(@json, :pretty => true) : MultiJson.encode(@json)
            else
              @response.body
            end
          else
            body = ''
          end

          Configuration.logger.log_response @response.code, took, body
        end
      end

    end

  end
end
