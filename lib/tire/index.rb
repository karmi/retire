module Tire
  class Index

    attr_reader :name, :response

    def initialize(name, &block)
      @name = name
      block.arity < 1 ? instance_eval(&block) : block.call(self) if block_given?
    end

    def url
      "#{Configuration.url}/#{@name}"
    end

    def exists?
      @response = Configuration.client.head("#{url}")
      @response.success?

    ensure
      curl = %Q|curl -I "#{url}"|
      logged('HEAD', curl)
    end

    def delete
      @response = Configuration.client.delete url
      @response.success?

    ensure
      curl = %Q|curl -X DELETE #{url}|
      logged('DELETE', curl)
    end

    def create(options={})
      @options = options
      @response = Configuration.client.post url, MultiJson.encode(options)
      @response.success? ? @response : false

    ensure
      curl = %Q|curl -X POST #{url} -d '#{MultiJson.encode(options)}'|
      logged('CREATE', curl)
    end

    def add_alias(alias_name, configuration={})
      Alias.create(configuration.merge( :name => alias_name, :index => @name ) )
    end

    def remove_alias(alias_name)
      Alias.find(alias_name) { |a| a.indices.delete @name }.save
    end

    def aliases(alias_name=nil)
      alias_name ? Alias.all(@name).select { |a| a.name == alias_name }.first : Alias.all(@name)
    end

    def mapping
      @response = Configuration.client.get("#{url}/_mapping")
      MultiJson.decode(@response.body)[@name]
    end

    def settings
      @response = Configuration.client.get("#{url}/_settings")
      MultiJson.decode(@response.body)[@name]['settings']
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

      url  = id ? "#{self.url}/#{type}/#{id}" : "#{self.url}/#{type}/"
      url += "?percolate=#{percolate}" if percolate

      @response = Configuration.client.post url, document
      MultiJson.decode(@response.body)

    ensure
      curl = %Q|curl -X POST "#{url}" -d '#{document}'|
      logged([type, id].join('/'), curl)
    end

    def bulk_store(documents, options={})
      payload = documents.map do |document|
        type = get_type_from_document(document, :escape => false) # Do not URL-escape the _type
        id   = get_id_from_document(document)

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
        @response = Configuration.client.post("#{url}/_bulk", payload.join("\n"))
        raise RuntimeError, "#{@response.code} > #{@response.body}" if @response && @response.failure?
        @response
      rescue StandardError => error
        if count < tries
          count += 1
          STDERR.puts "[ERROR] #{error.message}, retrying (#{count})..."
          retry
        else
          STDERR.puts "[ERROR] Too many exceptions occured, giving up. The HTTP response was: #{error.message}"
          raise if options[:raise]
        end

      ensure
        curl = %Q|curl -X POST "#{url}/_bulk" -d '{... data omitted ...}'|
        logged('BULK', curl)
      end
    end

    def import(klass_or_collection, options={})
      case
        when method = options.delete(:method)
          options = {:page => 1, :per_page => 1000}.merge options
          while documents = klass_or_collection.send(method.to_sym, options.merge(:page => options[:page])) \
                            and documents.to_a.length > 0

            documents = yield documents if block_given?

            bulk_store documents, options
            options[:page] += 1
          end

        when klass_or_collection.respond_to?(:map)
          documents = block_given? ? yield(klass_or_collection) : klass_or_collection
          bulk_store documents, options

        else
          raise ArgumentError, "Please pass either an Enumerable compatible class, or a collection object" +
                               "with a method for fetching records in batches (such as 'paginate')"
      end
    end

    def reindex(name, options={}, &block)
      new_index = Index.new(name)
      new_index.create(options) unless new_index.exists?

      search = Search::Search.new(self.name, :scroll => '10m', :search_type => 'scan', &block)
      Search::Scroll.new(search).each do |results|
        new_index.bulk_store results.map do |document|
          document.to_hash.except(:type, :_index, :_explanation, :_score, :_version, :highlight, :sort)
        end
      end
    end

    def remove(*args)
      if args.size > 1
        type, document = args
        type           = Utils.escape(type)
        id             = get_id_from_document(document) || document
      else
        document = args.pop
        type     = get_type_from_document(document)
        id       = get_id_from_document(document) || document
      end
      raise ArgumentError, "Please pass a document ID" unless id

      url    = "#{self.url}/#{type}/#{id}"
      result = Configuration.client.delete url
      MultiJson.decode(result.body) if result.success?

    ensure
      curl = %Q|curl -X DELETE "#{url}"|
      logged(id, curl)
    end

    def retrieve(type, id)
      raise ArgumentError, "Please pass a document ID" unless id

      type      = Utils.escape(type)
      url       = "#{self.url}/#{type}/#{id}"
      @response = Configuration.client.get url

      h = MultiJson.decode(@response.body)
      if Configuration.wrapper == Hash then h
      else
        return nil if h['exists'] == false
        document = h['_source'] || h['fields'] || {}
        document.update('id' => h['_id'], '_type' => h['_type'], '_index' => h['_index'], '_version' => h['_version'])
        Configuration.wrapper.new(document)
      end

    ensure
      curl = %Q|curl -X GET "#{url}"|
      logged(id, curl)
    end

    def refresh
      @response = Configuration.client.post "#{url}/_refresh", ''

    ensure
      curl = %Q|curl -X POST "#{url}/_refresh"|
      logged('_refresh', curl)
    end

    def open(options={})
      # TODO: Remove the duplication in the execute > rescue > ensure chain
      @response = Configuration.client.post "#{url}/_open", MultiJson.encode(options)
      MultiJson.decode(@response.body)['ok']

    ensure
      curl = %Q|curl -X POST "#{url}/_open"|
      logged('_open', curl)
    end

    def close(options={})
      @response = Configuration.client.post "#{url}/_close", MultiJson.encode(options)
      MultiJson.decode(@response.body)['ok']

    ensure
      curl = %Q|curl -X POST "#{url}/_close"|
      logged('_close', curl)
    end

    def analyze(text, options={})
      options = {:pretty => true}.update(options)
      params  = options.to_param
      @response = Configuration.client.get "#{url}/_analyze?#{params}", text
      @response.success? ? MultiJson.decode(@response.body) : false

    ensure
      curl = %Q|curl -X GET "#{url}/_analyze?#{params}" -d '#{text}'|
      logged('_analyze', curl)
    end

    def register_percolator_query(name, options={}, &block)
      options[:query] = Search::Query.new(&block).to_hash if block_given?

      @response = Configuration.client.put "#{Configuration.url}/_percolator/#{@name}/#{name}", MultiJson.encode(options)
      MultiJson.decode(@response.body)['ok']

    ensure
      curl = %Q|curl -X PUT "#{Configuration.url}/_percolator/#{@name}/?pretty=1" -d '#{MultiJson.encode(options)}'|
      logged('_percolator', curl)
    end

    def unregister_percolator_query(name)
      @response = Configuration.client.delete "#{Configuration.url}/_percolator/#{@name}/#{name}"
      MultiJson.decode(@response.body)['ok']

    ensure
      curl = %Q|curl -X DELETE "#{Configuration.url}/_percolator/#{@name}"|
      logged('_percolator', curl)
    end

    def percolate(*args, &block)
      document = args.shift
      type     = get_type_from_document(document)

      document = MultiJson.decode convert_document_to_json(document)

      query = Search::Query.new(&block).to_hash if block_given?

      payload = { :doc => document }
      payload.update( :query => query ) if query

      @response = Configuration.client.get "#{url}/#{type}/_percolate", MultiJson.encode(payload)
      MultiJson.decode(@response.body)['matches']

    ensure
      curl = %Q|curl -X GET "#{url}/#{type}/_percolate?pretty=1" -d '#{payload.to_json}'|
      logged('_percolate', curl)
    end

    def logged(endpoint='/', curl='')
      if Configuration.logger
        error = $!

        Configuration.logger.log_request endpoint, @name, curl

        code = @response ? @response.code : error.class rescue 'N/A'

        if Configuration.logger.level.to_s == 'debug'
          body = if @response
            defined?(Yajl) ? Yajl::Encoder.encode(@response.body, :pretty => true) : MultiJson.encode(@response.body)
          else
            error.message rescue ''
          end
        else
          body = ''
        end

        Configuration.logger.log_response code, nil, body
      end
    end

    def get_type_from_document(document, options={})
      options = {:escape => true}.merge(options)

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

      type ||= 'document'
      options[:escape] ? Utils.escape(type) : type
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
        when document.is_a?(String)
          Tire.warn "Passing the document as JSON string in Index#store has been deprecated, " +
                     "please pass an object which responds to `to_indexed_json` or a plain Hash."
          document
        when document.respond_to?(:to_indexed_json) then document.to_indexed_json
        else raise ArgumentError, "Please pass a JSON string or object with a 'to_indexed_json' method," +
                                  "'#{document.class}' given."
      end
    end

  end
end
