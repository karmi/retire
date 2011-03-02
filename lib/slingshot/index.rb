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

    def create(options={})
      # http://www.elasticsearch.org/guide/reference/api/admin-indices-create-index.html
      Configuration.client.post "#{Configuration.url}/#{@name}", Yajl::Encoder.encode(options)
    rescue
      false
    end

    def mapping
      JSON.parse( Configuration.client.get("#{Configuration.url}/#{@name}/_mapping") )[@name]
    end

    def store(*args)
      # TODO: Infer type from the document (hash property, method)

      if args.size > 1
        (type, document = args)
      else
        (document = args.pop; type = :document)
      end

      old_verbose, $VERBOSE = $VERBOSE, nil # Silence Object#id deprecation warnings
      id = case true
        when document.is_a?(Hash)                                           then document[:id] || document['id']
        when document.respond_to?(:id) && document.id != document.object_id then document.id
      end
      $VERBOSE = old_verbose

      document = case true
        when document.is_a?(String) then document
        when document.respond_to?(:to_indexed_json) then document.to_indexed_json
        else raise ArgumentError, "Please pass a JSON string or object with a 'to_indexed_json' method"
      end

      if id
        result = Configuration.client.post "#{Configuration.url}/#{@name}/#{type}/#{id}", document
      else
        result = Configuration.client.post "#{Configuration.url}/#{@name}/#{type}/", document
      end
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
