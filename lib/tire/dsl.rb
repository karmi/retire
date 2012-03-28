module Tire
  module DSL

    def configure(&block)
      Configuration.class_eval(&block)
    end

    def search(indices=nil, options={}, &block)
      if block_given?
        Search::Search.new(indices, options, &block)
      else
        payload = case options
          when Hash    then
            options
          when String  then
            Tire.warn "Passing the payload as a JSON string in Tire.search has been deprecated, " +
                       "please use the block syntax or pass a plain Hash."
            options
          else raise ArgumentError, "Please pass a Ruby Hash or String with JSON"
        end

        Search::Search.new(indices, :payload => payload)
      end
    rescue Exception => error
      STDERR.puts "[REQUEST FAILED] #{error.class} #{error.message rescue nil}\n"
      raise
    ensure
    end

    def index(name, &block)
      Index.new(name, &block)
    end

    def aliases
      @response = Configuration.client.get "#{Configuration.url}/_aliases"
      MultiJson.decode(@response.body).inject({}) do |acc, (index, value)|
        next acc if value['aliases'].empty?

        acc[index] = value['aliases'].keys
        acc
      end
    end

  end
end
