module Tire
  module DSL

    def configure(&block)
      Configuration.class_eval(&block)
    end

    def search(indices, options={}, &block)
      if block_given?
        Search::Search.new(indices, options, &block).perform
      else
        payload = case options
          when Hash    then options.to_json
          when String  then options
          else raise ArgumentError, "Please pass a Ruby Hash or String with JSON"
        end

        response = Configuration.client.post( "#{Configuration.url}/#{indices}/_search", payload)
        json     = MultiJson.decode(response.body)
        results  = Results::Collection.new(json, options)
      end
    rescue Exception => error
      STDERR.puts "[REQUEST FAILED] #{error.class} #{error.http_body rescue nil}\n"
      raise
    ensure
    end

    def index(name, &block)
      Index.new(name, &block)
    end

  end
end
