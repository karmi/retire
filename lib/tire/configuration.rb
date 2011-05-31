module Tire

  class Configuration

    def self.url(value=nil)
      @url    = value || @url || "http://localhost:9200"
    end

    def self.client(klass=nil)
      @client = klass || @client || Client::RestClient
    end

    def self.wrapper(klass=nil)
      @wrapper = klass || @wrapper || Results::Item
    end

    def self.logger(device=nil, options={})
      return @logger = Logger.new(device, options) if device
      @logger || nil
    end

    def self.reset(*properties)
      reset_variables = properties.empty? ? instance_variables : instance_variables & properties.map { |p|
        variable = "@#{p}"
        RUBY_VERSION < "1.9" ? variable : variable.to_sym
      }
      reset_variables.each { |v| instance_variable_set(v, nil) }
    end

  end

end
