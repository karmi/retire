module Tire
  class DeleteByQuery
    class DeleteByQueryRequestFailed < StandardError; end

    attr_reader :indices, :types, :query, :response, :json

    def initialize(indices=nil, options={}, &block)
      @indices = Array(indices)
      @types   = Array(options[:type]).flatten
      @options = options

      if block_given?
        @query = Search::Query.new
        block.arity < 1 ? @query.instance_eval(&block) : block.call(@query)
      else
        raise "no query given for #{self.class}"
      end
    end

    def perform
      @response = Configuration.client.delete url
      if @response.failure?
        STDERR.puts "[REQUEST FAILED] #{self.to_curl}\n"
        raise DeleteByQueryRequestFailed, @response.to_s
      end
      @json = MultiJson.decode(@response.body)
      true
    ensure
      logged
    end

    private

    def path
      [
        '/',
        indices.join(','),
        types.map { |type| Utils.escape(type) }.join(','),
        '_query',
      ].compact.join('/')
    end

    def url
      "#{Configuration.url}#{path}/?source=#{Utils.escape(to_json)}"
    end

    def to_json(options={})
      query.to_json
    end

    def to_curl
      %Q|curl -X DELETE '#{url}'|
    end

    def logged(endpoint='_query')
      if Configuration.logger

        Configuration.logger.log_request endpoint, indices, to_curl

        code = response.code rescue nil

        if Configuration.logger.level.to_s == 'debug'
          body = if json
            MultiJson.encode(json, :pretty => Configuration.pretty)
          else
            MultiJson.encode(MultiJson.load(response.body), :pretty => Configuration.pretty) rescue ''
          end
        else
          body = ''
        end

        Configuration.logger.log_response code || 'N/A', 'N/A', body || 'N/A'
      end
    end
  end
end
