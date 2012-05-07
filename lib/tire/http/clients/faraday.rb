require 'faraday'

module Tire
  module HTTP
    module Client
      class Faraday

        # Default middleware stack.
        DEFAULT_MIDDLEWARE = Proc.new do |builder|
          builder.adapter ::Faraday.default_adapter
        end

        class << self
          # A customized stack of Faraday middleware that will be used to make each request.
          attr_accessor :faraday_middleware

          def get(url, data = nil)
            request(:get, url, data)
          end

          def post(url, data)
            request(:post, url, data)
          end

          def put(url, data)
            request(:put, url, data)
          end

          def delete(url, data = nil)
            request(:delete, url, data)
          end

          def head(url)
            request(:head, url)
          end

          private
          def request(method, url, data = nil)
            conn = ::Faraday.new( &(faraday_middleware || DEFAULT_MIDDLEWARE) )
            response = conn.run_request(method, url, data, {})
            Response.new(response.body, response.status, response.headers)
          end
        end
      end
    end
  end
end
