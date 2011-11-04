module Tire

  module HTTP

    class Response
      attr_reader :body, :code, :headers

      def initialize(body, code, headers={})
        @body, @code, @headers = body, code.to_i, headers
      end

      def success?
        code > 0 && code < 400
      end

      def failure?
        ! success?
      end

      def to_s
        [code, body].join(' : ')
      end
    end

  end

end
