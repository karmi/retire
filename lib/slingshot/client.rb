module Slingshot

  module Client

    class Base
      def post(url, data)
        raise NoMethodError, "Implement this method in your client class"
      end
      def delete(url)
        raise NoMethodError, "Implement this method in your client class"
      end
    end

    class RestClient < Base
      def self.post(url, data)
        ::RestClient.post url, data
      end
      def self.delete(url)
        ::RestClient.delete url rescue nil
      end
    end

  end

end
