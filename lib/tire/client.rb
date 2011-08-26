module Tire

  module Client

    class RestClient
      def self.get(url, data=nil)
        ::RestClient::Request.new(:method => :get, :url => url, :payload => data).execute
      end
      def self.post(url, data)
        ::RestClient.post url, data
      end
      def self.put(url, data)
        ::RestClient.put url, data
      end
      def self.delete(url)
        ::RestClient.delete url rescue nil
      end
      def self.head(url)
        ::RestClient.head url
      end
    end

  end

end
