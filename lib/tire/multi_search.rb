module Tire
  module Search

    module Multi

      # Wraps the search definitions for Tire::Multi::Search
      #
      class SearchDefinitions
        include Enumerable

        attr_reader :names

        def initialize
          @names    = []
          @searches = []
        end

        def << value
          @names    << value[:name]
          @searches << value[:search]
        end

        def [] name
          @searches[ @names.index(name) ]
        end

        def each(&block)
          @searches.each(&block)
        end

        def size
          @searches.size
        end

        def to_a
          @searches
        end
      end

      # Wraps the search result sets for Tire::Multi::Search
      #
      class Results
        include Enumerable

        def initialize(searches, results)
          @searches = searches
          @results  = results
          @collection = @results.zip(@searches.to_a).map do |results, search|
            Tire::Results::Collection.new(results, search.options)
          end
        end

        # Return a specific result sets
        def [] name
          if index = @searches.names.index(name)
            @collection[ index ]
          end
        end

        def each(&block)
          @collection.each(&block)
        end

        def each_pair(&block)
          @searches.names.zip(@collection).each(&block)
        end

        def size
          @results.size
        end

        # Returns the multi-search result sets as a Hash with the search name
        # as key and the results as value.
        #
        def to_hash
          result = {}
          each_pair { |name,results| result[name] = results }
          result
        end
      end

      # Build and perform a [multi-search](http://elasticsearch.org/guide/reference/api/multi-search.html)
      # request.
      #
      #     s = Tire::Search::Multi::Search.new 'my-index' do
      #           search :names do
      #             query { match :name, 'john' }
      #           end
      #           search :counts, search_type: 'count' do
      #             query { match :_all, 'john' }
      #           end
      #           search :other, index: 'other-index' do
      #             query { string "first_name:john" }
      #           end
      #         end
      #
      # You can optionally pass an index and type to the constructor, using them as defaults
      # for searches which don't define them.
      #
      # Use the {#search} method to add a search definition to the request, passing it search options
      # as a Hash and the search definition itself using Tire's DSL.
      #
      class Search

        attr_reader :indices, :types, :path

        def initialize(indices=nil, options={}, &block)
          @indices  = Array(indices)
          @types    = Array(options.delete(:type)).map { |type| Utils.escape(type) }
          @options  = options
          @path     = ['/', @indices.join(','), @types.join(','), '_msearch'].compact.join('/').squeeze('/')
          @searches = Tire::Search::Multi::SearchDefinitions.new

          block.arity < 1 ? instance_eval(&block) : block.call(self) if block_given?
        end

        # Add a search definition to the multi-search request.
        #
        # The usual search options such as `search_type`, `routing`, etc. can be passed as a Hash,
        # and the search definition itself should be passed as a block using the Tire DSL.
        #
        def search(*args, &block)
          name_or_options = args.pop

          if name_or_options.is_a?(Hash)
            options = name_or_options
            name    = args.pop
          else
            name    = name_or_options
          end

          name    ||= @searches.size
          options ||= {}
          indices   = options.delete(:index) || options.delete(:indices)

          @searches << { :name => name, :search => Tire::Search::Search.new(indices, options, &block) }
        end

        # Without argument, returns the collection of search definitions.
        # With argument, returns a search definition by name or order.
        #
        def searches(name=nil)
          name ? @searches[ name ] : @searches
        end

        # Returns and array of search definition names
        #
        def names
          @searches.names
        end

        # Serializes the search definitions as an array of JSON definitions
        #
        def to_array
          @searches.map do |search|
            header = {}
            header.update(:index => search.indices.join(',')) unless search.indices.empty?
            header.update(:type  => search.types.join(','))   unless search.types.empty?
            header.update(:search_type => search.options[:search_type]) if search.options[:search_type]
            header.update(:routing     => search.options[:routing])     if search.options[:routing]
            header.update(:preference  => search.options[:preference])  if search.options[:preference]
            body   = search.to_hash
            [ header, body ]
          end.flatten
        end

        # Serializes the search definitions as a multi-line string payload
        #
        def to_payload
          to_array.map { |line| MultiJson.encode(line) }.join("\n") + "\n"
        end

        # Returns the request URL
        #
        def url
          [ Configuration.url, @path ].join
        end

        # Serializes the request URL parameters
        #
        def params
          options = @options.dup
          options.empty? ? '' : '?' + options.to_param
        end

        # Returns an enumerable collection of result sets.
        #
        # You can simply iterate over them:
        #
        #     search.results.each do |results|
        #       puts results.each.map(&:name)
        #     end
        #
        # To iterate over named result sets, use the `each_pair` method:
        #
        #     search.results.each_pair do |name,results|
        #       puts "Search #{name} got #{results.size} results"
        #     end
        #
        # To get a specific result set:
        #
        #     search.results[:myname]
        #
        def results
          @results  || perform and @results
        end

        # Returns the HTTP response
        #
        def response
          @response || perform and @response
        end

        # Returns the raw JSON as a Hash
        #
        def json
          @json     || perform and @json
        end

        def perform
          @response = Configuration.client.get(url + params, to_payload)
          if @response.failure?
            STDERR.puts "[REQUEST FAILED] #{to_curl}\n"
            raise SearchRequestFailed, @response.to_s
          end
          @json     = MultiJson.decode(@response.body)
          @results  = Tire::Search::Multi::Results.new @searches, @json['responses']
          return self
        ensure
          logged
        end

        def to_curl
          %Q|curl -X GET '#{url}#{params.empty? ? '?' : params.to_s + '&'}pretty' -d '\n#{to_payload}'|
        end

        def logged(endpoint='_msearch')
          if Configuration.logger

            Configuration.logger.log_request endpoint, indices, to_curl

            took = @json['took']  rescue nil
            code = @response.code rescue nil

            if Configuration.logger.level.to_s == 'debug'
              body = if @json
                MultiJson.encode( @json, :pretty => Configuration.pretty)
              else
                MultiJson.encode( MultiJson.load(@response.body), :pretty => Configuration.pretty) rescue ''
              end
            else
              body = ''
            end

            Configuration.logger.log_response code || 'N/A', took || 'N/A', body || 'N/A'
          end
        end
      end

    end

  end
end
