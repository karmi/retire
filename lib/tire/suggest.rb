module Tire
  module Suggest
    class SuggestRequestFailed < StandardError; end

    class Suggest

      attr_reader :indices, :suggestion, :options

      def initialize(indices=nil, options={}, &block)
        if indices.is_a?(Hash)
          @indices = indices.keys
        else
          @indices = Array(indices)
        end

        #TODO no options for now
        @options = options

        @path    = ['/', @indices.join(','), '_suggest'].compact.join('/').squeeze('/')

        block.arity < 1 ? instance_eval(&block) : block.call(self) if block_given?
      end

      def suggestion(name, &block)
        @suggestion = Suggestion.new(name, &block)
        self
      end

      def multi(&block)
        @suggestion = MultiSuggestion.new(&block)
        self
      end

      def results
        @results  || (perform; @results)
      end

      def response
        @response || (perform; @response)
      end

      def json
        @json || (perform; @json)
      end

      def url
        Configuration.url + @path
      end

      def params
        options = @options.except(:wrapper, :payload, :load)
        options.empty? ? '' : '?' + options.to_param
      end

      def perform
        @response = Configuration.client.get(self.url + self.params, self.to_json)
        if @response.failure?
          STDERR.puts "[REQUEST FAILED] #{self.to_curl}\n"
          raise Tire::Search::SearchRequestFailed, @response.to_s
        end
        @json = MultiJson.decode(@response.body)
        @results = Results::Suggestions.new(@json, @options)
        return self
      ensure
        logged
      end

      def to_curl
        to_json_escaped = to_json.gsub("'",'\u0027')
        %Q|curl -X GET '#{url}#{params.empty? ? '?' : params.to_s + '&'}pretty' -d '#{to_json_escaped}'|
      end

      def to_hash
        request = {}
        request.update( @suggestion.to_hash )
        request
      end

      def to_json(options={})
        payload = to_hash
        MultiJson.encode(payload, :pretty => Configuration.pretty)
      end

      def logged(endpoint='_search')
        if Configuration.logger

          Configuration.logger.log_request endpoint, indices, to_curl

          took = @json['took']  rescue nil
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

          Configuration.logger.log_response code || 'N/A', took || 'N/A', body || 'N/A'
        end
      end
    end
  end
end

