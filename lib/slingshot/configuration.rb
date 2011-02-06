module Slingshot

  class Configuration

    # Retrieve URL for ElasticSearch server/cluster
    #
    def self.url
      @url ||= "http://localhost:9200"
    end

    # Set URL for ElasticSearch server/cluster
    #
    def self.url=(value)
      @url = value
    end

  end

end
