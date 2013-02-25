module Tire
  module Search
    class CountRequestFailed < StandardError; end

    class Count

      attr_reader :indices, :types, :query, :response, :json

      def initialize(indices=nil, options={}, &block)
        @indices = Array(indices)
        @types   = Array(options.delete(:type)).map { |type| Utils.escape(type) }
        @options = options

        @path    = ['/', @indices.join(','), @types.join(','), '_count'].compact.join('/').squeeze('/')

        if block_given?
          @query = Query.new
          block.arity < 1 ? @query.instance_eval(&block) : block.call(@query)
        end
      end

      def url
        Configuration.url + @path
      end

      def params
        options = @options.except(:wrapper)
        options.empty? ? '' : '?' + options.to_param
      end

      def perform
        @response = Configuration.client.get self.url + self.params, self.to_json
        if @response.failure?
          STDERR.puts "[REQUEST FAILED] #{self.to_curl}\n"
          raise CountRequestFailed, @response.to_s
        end
        @json     = MultiJson.decode(@response.body)
        @value    = @json['count']
        return self
      ensure
        logged
      end

      def value
        @value || (perform and return @value)
      end

      def to_json(options={})
        @query.to_json if @query
      end

      def to_curl
        if to_json
          to_json_escaped = to_json.gsub("'",'\u0027')
          %Q|curl -X GET '#{url}#{params.empty? ? '?' : params.to_s + '&'}pretty' -d '#{to_json_escaped}'|
        else
          %Q|curl -X GET '#{url}#{params.empty? ? '?' : params.to_s + '&'}pretty'|
        end
      end

      def logged(endpoint='_count')
        if Configuration.logger

          Configuration.logger.log_request endpoint, indices, to_curl

          code = @response.code rescue nil

          if Configuration.logger.level.to_s == 'debug'
            body = if @json
              MultiJson.encode( @json, :pretty => Configuration.pretty)
            else
              MultiJson.encode( MultiJson.load(@response.body), :pretty => Configuration.pretty) rescue ''
            end
          else
            body = ''
          end

          Configuration.logger.log_response code || 'N/A', 'N/A', body || 'N/A'
        end
      end

    end

  end
end
