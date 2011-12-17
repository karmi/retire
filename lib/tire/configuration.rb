module Tire

  class Configuration

    def self.urls
      @urls || ["http://localhost:9200"]
    end

    def self.url(*values)
      @urls = values.map{|value| value.to_s.gsub(%r|/*$|, '')} if values.any?
      urls.respond_to?(:sample) ? urls.sample : urls.choice
    end

    def self.client(klass=nil)
      @client = klass || @client || HTTP::Client::RestClient
    end

    def self.wrapper(klass=nil)
      @wrapper = klass || @wrapper || Results::Item
    end

    def self.logger(device=nil, options={})
      return @logger = Logger.new(device, options) if device
      @logger || nil
    end

    def self.reset(*properties)
      reset_variables = properties.empty? ? instance_variables : instance_variables.map { |p| p.to_s} & \
                                                                 properties.map         { |p| "@#{p}" }
      reset_variables.each { |v| instance_variable_set(v.to_sym, nil) }
    end

  end

end
