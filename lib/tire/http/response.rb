module Tire
  module HTTP
    class Response
      attr_reader :body, :code, :headers
      def initialize(body, code, headers = {})
        @body, @code, @headers = body, code, headers
      end
    end
  end
end
