module Tire
  class Error < StandardError; end

  class DocumentNotValid < Error
    attr_reader :document

    def initialize(document)
      @document
      super("Validation failed: #{document.errors.full_messages.join(", ")}")
    end
  end

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
