module Tire
  module DSL

    def configure(&block)
      Configuration.class_eval(&block)
    end

    def search(indices=nil, options={}, &block)
      if block_given?
        Search::Search.new(indices, options, &block)
      else
        case options
          when Hash    then
            payload = (options[:payload] || options).to_json
            options = {} unless options.delete(:payload)
          when String  then
            payload = options
            options = {}
          else raise ArgumentError, "Please pass a Ruby Hash or String with JSON"
        end

        search = Search::Search.new(indices, options) { |search| nil }
        response = Configuration.client.post search.url, payload
        raise Tire::Search::SearchRequestFailed, response.to_s if response.failure?
        json     = MultiJson.decode(response.body)
        results  = Results::Collection.new(json, options)
      end
    rescue Exception => error
      STDERR.puts "[REQUEST FAILED] #{error.class} #{error.message rescue nil}\n"
      raise
    ensure
    end

    def index(name, &block)
      Index.new(name, &block)
    end

  end
end
