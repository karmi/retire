module Tire

  module Client

    class RestClient

      def self.get(url, data=nil)
        tire_http_response ::RestClient::Request.new(:method => :get, :url => url, :payload => data).execute(&just_response)
      end

      def self.post(url, data)
        tire_http_response ::RestClient.post(url, data, &just_response)
      end

      def self.put(url, data)
        tire_http_response ::RestClient.put(url, data, &just_response)
      end

      def self.delete(url)
        tire_http_response ::RestClient.delete(url, &just_response)
      end

      def self.head(url)
        tire_http_response ::RestClient.head(url, &just_response)
      end

      def self.tire_http_response(response)
        Tire::HTTP::Response.new response.body, response.code, response.headers
      end

      def self.just_response
        lambda {|response, request, result| response }
      end
    end

  end

end
