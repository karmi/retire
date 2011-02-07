module Slingshot

  class Configuration

    def self.url(value=nil)
      @url    = value || @url || "http://localhost:9200"
    end

    def self.client(klass=nil)
      @client = klass || @client || Client::RestClient
    end

  end

end
