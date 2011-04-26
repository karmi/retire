module Slingshot
  class Index

    attr_reader :name

    def initialize(name, &block)
      @name = name
      instance_eval(&block) if block_given?
    end

    def exists?
      !!Configuration.client.get("#{Configuration.url}/#{@name}/_status")
    rescue Exception => error
      false
    end

    def delete
      # FIXME: RestClient does not return response for DELETE requests?
      @response = Configuration.client.delete "#{Configuration.url}/#{@name}"
      return @response.body =~ /error/ ? false : true
    rescue Exception => error
      false
    ensure
      curl = %Q|curl -X DELETE "#{Configuration.url}/#{@name}"|
      logged(error, 'DELETE', curl)
    end

    def create(options={})
      @options = options
      @response = Configuration.client.post "#{Configuration.url}/#{@name}", Yajl::Encoder.encode(options)
    rescue Exception => error
      false
    ensure
      curl = %Q|curl -X POST "#{Configuration.url}/#{@name}" -d '#{Yajl::Encoder.encode(options, :pretty => true)}'|
      logged(error, 'CREATE', curl)
    end

    def mapping
      @response = Configuration.client.get("#{Configuration.url}/#{@name}/_mapping")
      JSON.parse(@response.body)[@name]
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

      url = id ? "#{Configuration.url}/#{@name}/#{type}/#{id}" : "#{Configuration.url}/#{@name}/#{type}/"

      @response = Configuration.client.post url, document
      JSON.parse(@response.body)

    rescue Exception => error
      raise
    ensure
      curl = %Q|curl -X POST "#{url}" -d '#{document}'|
      logged(error, "/#{@name}/#{type}/", curl)
    end

    def bulk_store documents
      create unless exists?

      payload = documents.map do |document|
        old_verbose, $VERBOSE = $VERBOSE, nil # Silence Object#id deprecation warnings
        id = case
          when document.is_a?(Hash)                                           then document[:id] || document['id']
          when document.respond_to?(:id) && document.id != document.object_id then document.id
        end
        $VERBOSE = old_verbose

        type = case
          when document.is_a?(Hash)                 then document[:type] || document['type']
          when document.respond_to?(:document_type) then document.document_type
        end || 'document'

        output = []
        output << %Q|{"index":{"_index":"#{@name}","_type":"#{type}","_id":"#{id}"}}|
        output << document.to_indexed_json
        output.join("\n")
      end
      payload << ""

      tries = 5
      count = 0

      begin
        # STDERR.puts "Posting payload..."
        # STDERR.puts payload.join("\n")
        Configuration.client.post("#{Configuration.url}/_bulk", payload.join("\n"))
      rescue Exception => error
        if count < tries
          count += 1
          STDERR.puts "[ERROR] #{error.message}:#{error.http_body rescue nil}, retrying (#{count})..."
          retry
        else
          STDERR.puts "[ERROR] Too many exceptions occured, giving up..."
          STDERR.puts "Response: #{error.http_body rescue nil}"
          raise
        end
      ensure
        curl = %Q|curl -X POST "#{Configuration.url}/_bulk" -d '{... data omitted ...}'|
        logged(error, 'BULK', curl)
      end
    end

    def remove(*args)
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
        else document
      end
      $VERBOSE = old_verbose

      result = Configuration.client.delete "#{Configuration.url}/#{@name}/#{type}/#{id}"
      JSON.parse(result) if result
    end

    def retrieve(type, id)
      @response = Configuration.client.get "#{Configuration.url}/#{@name}/#{type}/#{id}"
      h = JSON.parse(@response.body)
      if Configuration.wrapper == Hash then h
      else
        document = {}
        document = h['_source'] ? document.update( h['_source'] ) : document.update( h['fields'] )
        document.update('id' => h['_id'], '_version' => h['_version'])
        Configuration.wrapper.new(document)
      end
    end

    def refresh
      @response = Configuration.client.post "#{Configuration.url}/#{@name}/_refresh", ''
    rescue Exception => error
      raise
    ensure
      curl = %Q|curl -X POST "#{Configuration.url}/#{@name}/_refresh"|
      logged(error, '_refresh', curl)
    end

    def logged(error=nil, endpoint='/', curl='')
      if Configuration.logger

        Configuration.logger.log_request endpoint, @name, curl

        code = @response ? @response.code : error.message rescue 200

        if Configuration.logger.level.to_s == 'debug'
          # FIXME: Depends on RestClient implementation
          body = @response ? Yajl::Encoder.encode(@response.body, :pretty => true) : error.http_body rescue ''
        else
          body = ''
        end

        Configuration.logger.log_response code, nil, body
      end
    end

  end
end
