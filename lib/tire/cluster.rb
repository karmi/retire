module Tire
  class Cluster

    def initialize(&block)
      block.arity < 1 ? instance_eval(&block) : block.call(self) if block_given?
      self
    end

    def url
      "#{Configuration.url}/_cluster"
    end

    def health(opts = {})
      health_url = "#{url}/health?" + opts.to_param
      response  = Configuration.client.get health_url, MultiJson.encode({})

      response.success? ? MultiJson.decode(response.body) : false
    ensure
      logged('GET', format_curl(health_url, {}))
    end

    private

    def format_curl(url, options)
      %Q|curl -X GET #{url} -d '#{MultiJson.encode({}, :pretty => Configuration.pretty)}'|
    end

    def logged(endpoint='/_cluster', curl='')
      if Configuration.logger
        error = $!

        Configuration.logger.log_request endpoint, curl

        code = @response ? @response.code : error.class rescue 'N/A'

        if Configuration.logger.level.to_s == 'debug'
          body = if @response
            MultiJson.encode( MultiJson.load(@response.body), :pretty => Configuration.pretty)
          else
            MultiJson.encode( MultiJson.load(error.message), :pretty => Configuration.pretty) rescue ''
          end
        else
          body = ''
        end

        Configuration.logger.log_response code, nil, body
      end
    end

  end
end