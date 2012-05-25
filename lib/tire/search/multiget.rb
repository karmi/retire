module Tire
  module Search
    class MultiGet
      attr_reader :index, :type, :json, :options

      def initialize(*args, &block)
        if block_given?
          @index = args.shift
          @options = args.shift || {}
        else
          @index = args.shift
          @type = args.shift
          @ids = args.shift
          @options = args.shift
        end

        @path = ['/', @index, @type, '/_mget'].compact.join('/').squeeze('/')

        block.arity < 1 ? instance_eval(&block) : block.call(self) if block_given?
      end

      def results
        @result || (perform; @results)
      end

      def response
        @response || (perform; @response)
      end

      def url
        Configuration.url + @path
      end

      def doc(id, options={})
        doc = { '_id' => id }
        doc['_index'] = options.delete(:index) if options[:index]
        doc['_type'] = options.delete(:type) if options[:type]
        doc['fields'] = options.delete(:fields) if options[:fields]

        @docs ||= []
        @docs << doc
      end

      def perform
        @response = Configuration.client.get(self.url, self.to_json)
        if @response.failure?
          STDERR.puts "[REQUEST FAILED] #{self.to_curl}\n"
          raise SearchRequestFailed, @response.to_s
        end
        @json = MultiJson.decode(@response.body)
        @results = Results::MultiGetCollection.new(@json, @options)
        return self
      ensure
        logged
      end

      def to_curl
        %Q|curl -X GET "#{url}'?pretty=true" -d '#{to_json}'|
      end

      def to_hash
        request = {}
        request.update( { :ids => @ids } ) if @ids
        request.update( { :docs => @docs } ) if @docs
        request
      end

      def to_json
        to_hash.to_json
      end

      def logged(error=nil)
        if Configuration.logger

          Configuration.logger.log_request '_mget', index, to_curl

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
