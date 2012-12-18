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
        unless options.empty?
          Search::Search.new(indices, :payload => payload)
        else
          Search::Search.new(indices)
        end
      end
    rescue Exception => error
      STDERR.puts "[REQUEST FAILED] #{error.class} #{error.message rescue nil}\n"
      raise
    ensure
    end

    # Build and perform a [multi-search](http://elasticsearch.org/guide/reference/api/multi-search.html)
    # request.
    #
    #     s = Tire.multi_search 'clients' do
    #           search :names do
    #             query { match :name, 'carpenter' }
    #           end
    #           search :counts, search_type: 'count' do
    #             query { match [:name, :street, :occupation], 'carpenter' }
    #           end
    #           search :vip, index: 'clients-vip' do
    #             query { string "last_name:carpenter" }
    #           end
    #           search() { query {all} }
    #         end
    #
    # The DSL allows you to perform multiple searches and get corresponding results
    # in a single HTTP request, saving network roundtrips.
    #
    # Use the `search` method in the block to define a search request with the
    # regular Tire's DSL (`query`, `facet`, etc).
    #
    # You can pass options such as `search_type`, `routing`, etc.,
    # as well as a different `index` and/or `type` to individual searches.
    #
    # You can give single searches names, to be able to refer to them later.
    #
    # The results are returned as an enumerable collection of {Tire::Results::Collection} instances.
    #
    # You may simply iterate over them with `each`:
    #
    #     s.results.each do |results|
    #       puts results.map(&:name)
    #     end
    #
    # To iterate over named results, use the `each_pair` method:
    #
    #     s.results.each_pair do |name,results|
    #       puts "Search #{name} got #{results.size} results"
    #     end
    #
    # You can get a specific named result:
    #
    #     search.results[:vip]
    #
    # You can mix & match named and non-named searches in the definition; the non-named
    # searches will be zero-based numbered, so you can refer to them:
    #
    #     search.results[3] # Results for the last query
    #
    # To log the multi-search request, use the standard `to_curl` method (or set up a logger):
    #
    #     print search.to_curl
    #
    def multi_search(indices=nil, options={}, &block)
      Search::Multi::Search.new(indices, options, &block)
    rescue Exception => error
      STDERR.puts "[REQUEST FAILED] #{error.class} #{error.message rescue nil}\n"
      raise
    ensure
    end
    alias :multisearch :multi_search
    alias :msearch     :multi_search

    def index(name, &block)
      Index.new(name, &block)
    end

    def scan(names, options={}, &block)
      Search::Scan.new(names, options, &block)
    end

    def aliases
      Alias.all
    end

  end
end
