module Slingshot
  class Index

    def initialize(name, &block)
      @name = name
      instance_eval(&block) if block_given?
    end

    def delete
      response = Configuration.client.delete "#{Configuration.url}/#{@name}"
      return response =~ /error/ ? false : true
    rescue
      false
    end

    def create
      Configuration.client.post "#{Configuration.url}/#{@name}", ''
    rescue
      false
    end

    def refresh
      Configuration.client.post "#{Configuration.url}/#{@name}/_refresh", ''
    end

  end
end
