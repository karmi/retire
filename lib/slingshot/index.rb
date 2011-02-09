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

    def store(*args)
      if args.size > 1
        (type, document = args)
      else
        (document = args.pop; type = :document)
      end
      document = case true
        when document.is_a?(String) then document
        when document.respond_to?(:to_indexed_json) then document.to_indexed_json
        else raise ArgumentError, "Please pass a JSON string or object with a 'to_indexed_json' method"
      end
      result = Configuration.client.post "#{Configuration.url}/#{@name}/#{type}/", document
      JSON.parse(result)
    end

    def retrieve(type, id)
      result = Configuration.client.get "#{Configuration.url}/#{@name}/#{type}/#{id}"
      h = JSON.parse(result)
      if Configuration.wrapper == Hash then h
      else
        document = h['_source'] ? h['_source'] : h['fields']
        h.update document if document
        Configuration.wrapper.new(h)
      end
    end

    def refresh
      Configuration.client.post "#{Configuration.url}/#{@name}/_refresh", ''
    end

  end
end
