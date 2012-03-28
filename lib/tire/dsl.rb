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

    # Perform a multi-search
    #
    # @see http://www.elasticsearch.org/guide/reference/api/multi-search.html
    def msearch(options = {}, &block)
      raise ArgumentError.new('block not supplied') unless block_given?
      Search::Msearch.new(options, &block)
    end

    def index(name, &block)
      Index.new(name, &block)
    end

  end
end
