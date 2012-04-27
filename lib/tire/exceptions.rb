module Tire
  class Error < StandardError; end

  class RequestError < Error
    attr_reader :response

    def initialize(response)
      @response = response
    end

    def inspect
      "request error: #{response.inspect}"
    end

    def to_s
      inspect
    end
  end
end
