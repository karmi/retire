module Tire

  module Client

    class Base
      def get(url)
        raise_no_method_error
      end
      def post(url, data)
        raise_no_method_error
      end
      def put(url, data)
        raise NoMethodError, "Implement this method in your client class"
      end
      def delete(url)
        raise_no_method_error
      end
      def raise_no_method_error
        raise NoMethodError, "Implement this method in your client class"
      end
    end

    class RestClient < Base
      def self.get(url)
        ::RestClient.get url
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
    end

  end

end
