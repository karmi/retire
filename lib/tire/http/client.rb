module Tire

  module HTTP

    module Client

      class RestClient
        ConnectionExceptions = [::RestClient::ServerBrokeConnection, ::RestClient::RequestTimeout, Errno::ECONNREFUSED]

        def self.get(url, data=nil)
          perform(url) { ::RestClient::Request.new(:method => :get, :url => url, :payload => data).execute }
        end

        def self.post(url, data)
          perform(url) { ::RestClient.post(url, data) }
        end

        def self.put(url, data)
          perform(url) { ::RestClient.put(url, data) }
        end

        def self.delete(url)
          perform(url) { ::RestClient.delete(url) }
        end

        def self.head(url)
          perform(url) { ::RestClient.head(url) }
        end

        private

        def self.perform(url, &block)
          response = yield
          Response.new response.body, response.code, response.headers
        rescue *ConnectionExceptions => e
          raise e, "Unable to connect to ElasticSearch on #{url}"
        rescue ::RestClient::Exception => e
          Response.new e.http_body, e.http_code
        end

      end

    end

  end

end
