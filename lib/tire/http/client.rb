module Tire

  module HTTP

    module Client

      class RestClient

        def self.get(url, data=nil)
          perform ::RestClient::Request.new(:method => :get, :url => url, :payload => data).execute
        rescue Exception => e
          Response.new e.http_body, e.http_code
        end

        def self.post(url, data)
          perform ::RestClient.post(url, data)
        rescue Exception => e
          Response.new e.http_body, e.http_code
        end

        def self.put(url, data)
          perform ::RestClient.put(url, data)
        rescue Exception => e
          Response.new e.http_body, e.http_code
        end

        def self.delete(url)
          perform ::RestClient.delete(url)
        rescue Exception => e
          Response.new e.http_body, e.http_code
        end

        def self.head(url)
          perform ::RestClient.head(url)
        rescue Exception => e
          Response.new e.http_body, e.http_code
        end

        private

        def self.perform(response)
          Response.new response.body, response.code, response.headers
        end

      end

    end

  end

end
