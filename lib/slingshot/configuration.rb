module Slingshot

  class Configuration

    def self.url(value=nil)
      @url    = value || @url || "http://localhost:9200"
    end

    def self.client(klass=nil)
      @client = klass || @client || Client::RestClient
    end

    def self.reset(*properties)
      reset_variables = properties.empty? ? instance_variables : instance_variables & properties.map { |p| "@#{p}" }
      reset_variables.each { |v| instance_variable_set(v, nil) }
    end

  end

end
