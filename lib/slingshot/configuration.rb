module Slingshot

  class Configuration

    def self.url
      @url ||= "http://localhost:9200"
    end

    def self.url=(value)
      @url = value
    end

    def self.client
      @client ||= Client::RestClient
    end

    def self.client=(klass)
      @client = klass
    end

  end

end
