module Tire
  class Index

    attr_reader :name

    def initialize(name, &block)
      @name = name
      instance_eval(&block) if block_given?
    end

    def exists?
      Configuration.client.head("#{Configuration.url}/#{@name}").success?
    end

    def delete
      @response = Configuration.client.delete "#{Configuration.url}/#{@name}"
      return @response.success?
    ensure
      curl = %Q|curl -X DELETE "#{Configuration.url}/#{@name}"|
      logged(@response.body, 'DELETE', curl)
    end

    def create(options={})
      @options = options
      @response = Configuration.client.post "#{Configuration.url}/#{@name}", MultiJson.encode(options)
      @response.success? ? @response : false
    ensure
      curl = %Q|curl -X POST "#{Configuration.url}/#{@name}" -d '#{MultiJson.encode(options)}'|
      logged(@response.body, 'CREATE', curl)
    end

    def mapping
      @response = Configuration.client.get("#{Configuration.url}/#{@name}/_mapping")
      MultiJson.decode(@response.body)[@name]
    end

    def store(*args)
      document, options = args
      type = get_type_from_document(document)

      if options
        percolate = options[:percolate]
        percolate = "*" if percolate === true
      end

      id       = get_id_from_document(document)
      document = convert_document_to_json(document)

      url  = id ? "#{Configuration.url}/#{@name}/#{type}/#{id}" : "#{Configuration.url}/#{@name}/#{type}/"
      url += "?percolate=#{percolate}" if percolate

      @response = Configuration.client.post url, document
      MultiJson.decode(@response.body)

    rescue Exception => error
      raise
    ensure
      curl = %Q|curl -X POST "#{url}" -d '#{document}'|
      logged(error, "/#{@name}/#{type}/", curl)
    end

    def bulk_store documents
      payload = documents.map do |document|
        id   = get_id_from_document(document)
        type = get_type_from_document(document)

        STDERR.puts "[ERROR] Document #{document.inspect} does not have ID" unless id

        output = []
        output << %Q|{"index":{"_index":"#{@name}","_type":"#{type}","_id":"#{id}"}}|
        output << convert_document_to_json(document)
        output.join("\n")
      end
      payload << ""

      tries = 5
      count = 0

      begin
        response = Configuration.client.post("#{Configuration.url}/_bulk", payload.join("\n"))
        raise RuntimeError, "#{response.code} > #{response.body}" if response.failure?
        response
      rescue Exception => error
        if count < tries
          count += 1
          STDERR.puts "[ERROR] #{error.message}, retrying (#{count})..."
          retry
        else
          STDERR.puts "[ERROR] Too many exceptions occured, giving up. The HTTP response was: #{error.message}"
        end
      ensure
        curl = %Q|curl -X POST "#{Configuration.url}/_bulk" -d '{... data omitted ...}'|
        logged(error, 'BULK', curl)
      end
    end

    def import(klass_or_collection, method=nil, options={})
      case
        when method
          options = {:page => 1, :per_page => 1000}.merge options
          while documents = klass_or_collection.send(method.to_sym, options.merge(:page => options[:page])) \
                            and documents.to_a.length > 0

            documents = yield documents if block_given?

            bulk_store documents
            options[:page] += 1
          end

        when klass_or_collection.respond_to?(:map)
          documents = block_given? ? yield(klass_or_collection) : klass_or_collection
          bulk_store documents

        else
          raise ArgumentError, "Please pass either a collection of objects, " +
                               "or method for fetching records, or Enumerable compatible class"
      end
    end

    def remove(*args)
      if args.size > 1
        type, document = args
        id             = get_id_from_document(document) || document
      else
        document = args.pop
        type     = get_type_from_document(document)
        id       = get_id_from_document(document) || document
      end
      raise ArgumentError, "Please pass a document ID" unless id

      result = Configuration.client.delete "#{Configuration.url}/#{@name}/#{type}/#{id}"
      MultiJson.decode(result.body) if result.success?
    end

    def retrieve(type, id)
      raise ArgumentError, "Please pass a document ID" unless id

      @response = Configuration.client.get "#{Configuration.url}/#{@name}/#{type}/#{id}"
      h = MultiJson.decode(@response.body)
      if Configuration.wrapper == Hash then h
      else
        document = {}
        document = h['_source'] ? document.update( h['_source'] ) : document.update( h['fields'] )
        document.update('id' => h['_id'], '_type' => h['_type'], '_index' => h['_index'], '_version' => h['_version'])
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

    def open(options={})
      # TODO: Remove the duplication in the execute > rescue > ensure chain
      @response = Configuration.client.post "#{Configuration.url}/#{@name}/_open", MultiJson.encode(options)
      MultiJson.decode(@response.body)['ok']
    rescue Exception => error
      raise
    ensure
      curl = %Q|curl -X POST "#{Configuration.url}/#{@name}/open"|
      logged(error, '_open', curl)
    end

    def close(options={})
      # TODO: Remove the duplication in the execute > rescue > ensure chain
      @response = Configuration.client.post "#{Configuration.url}/#{@name}/_close", MultiJson.encode(options)
      MultiJson.decode(@response.body)['ok']
    rescue Exception => error
      raise
    ensure
      curl = %Q|curl -X POST "#{Configuration.url}/#{@name}/_close"|
      logged(error, '_close', curl)
    end

    def register_percolator_query(name, options={}, &block)
      options[:query] = Search::Query.new(&block).to_hash if block_given?

      @response = Configuration.client.put "#{Configuration.url}/_percolator/#{@name}/#{name}", MultiJson.encode(options)
      MultiJson.decode(@response.body)['ok']
      rescue Exception => error
        raise
      ensure
        curl = %Q|curl -X PUT "#{Configuration.url}/_percolator/#{@name}/?pretty=1" -d '#{MultiJson.encode(options)}'|
        logged(error, '_percolator', curl)
    end

    def unregister_percolator_query(name)
      @response = Configuration.client.delete "#{Configuration.url}/_percolator/#{@name}/#{name}"
      MultiJson.decode(@response.body)['ok']
      rescue Exception => error
        raise
      ensure
        curl = %Q|curl -X DELETE "#{Configuration.url}/_percolator/#{@name}"|
        logged(error, '_percolator', curl)
    end

    def percolate(*args, &block)
      document = args.shift
      type     = get_type_from_document(document)

      document = MultiJson.decode convert_document_to_json(document)

      query = Search::Query.new(&block).to_hash if block_given?

      payload = { :doc => document }
      payload.update( :query => query ) if query

      @response = Configuration.client.get "#{Configuration.url}/#{@name}/#{type}/_percolate", MultiJson.encode(payload)
      MultiJson.decode(@response.body)['matches']

      rescue Exception => error
        # raise
      ensure
        curl = %Q|curl -X GET "#{Configuration.url}/#{@name}/#{type}/_percolate?pretty=1" -d '#{payload.to_json}'|
        logged(error, '_percolate', curl)
    end

    def logged(error=nil, endpoint='/', curl='')
      if Configuration.logger

        Configuration.logger.log_request endpoint, @name, curl

        code = @response ? @response.code : error.message rescue 200

        if Configuration.logger.level.to_s == 'debug'
          # FIXME: Depends on RestClient implementation
          body = if @response
            defined?(Yajl) ? Yajl::Encoder.encode(@json, :pretty => true) : MultiJson.encode(@json)
          else
            error.http_body rescue ''
          end
        else
          body = ''
        end

        Configuration.logger.log_response code, nil, body
      end
    end

    def get_type_from_document(document)
      old_verbose, $VERBOSE = $VERBOSE, nil # Silence Object#type deprecation warnings
      type = case
        when document.respond_to?(:document_type)
          document.document_type
        when document.is_a?(Hash)
          document[:_type] || document['_type'] || document[:type] || document['type']
        when document.respond_to?(:_type)
          document._type
        when document.respond_to?(:type) && document.type != document.class
          document.type
        end
      $VERBOSE = old_verbose
      type || :document
    end

    def get_id_from_document(document)
      old_verbose, $VERBOSE = $VERBOSE, nil # Silence Object#id deprecation warnings
      id = case
        when document.is_a?(Hash)
          document[:_id] || document['_id'] || document[:id] || document['id']
        when document.respond_to?(:id) && document.id != document.object_id
          document.id
      end
      $VERBOSE = old_verbose
      id
    end

    def convert_document_to_json(document)
      document = case
        when document.is_a?(String) then document
        when document.respond_to?(:to_indexed_json) then document.to_indexed_json
        else raise ArgumentError, "Please pass a JSON string or object with a 'to_indexed_json' method"
      end
    end

  end
end
