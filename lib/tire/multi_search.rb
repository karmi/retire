module Tire
  module Search

    module Multi

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

      class Results
        include Enumerable

        def initialize(searches, results)
          @searches = searches
          @results  = results
          @collection = @results.zip(@searches.to_a).map do |results, search|
            Tire::Results::Collection.new(results, search.options)
          end
        end

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

        def to_hash
          result = {}
          each_pair { |name,results| result[name] = results }
          result
        end
      end

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

        def searches(name=nil)
          name ? @searches[ name ] : @searches
        end

        def names
          @searches.names
        end

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

        def to_payload
          to_array.map { |line| MultiJson.encode(line) }.join("\n") + "\n"
        end

        def url
          [ Configuration.url, @path ].join
        end

        def params
          options = @options.dup
          options.empty? ? '' : '?' + options.to_param
        end

        def results
          @results  || perform and @results
        end

        def response
          @response || perform and @response
        end

        def json
          @json     || perform and @json
        end

        def perform
          @responses = Configuration.client.get(url + params, to_payload)
          if @responses.failure?
            STDERR.puts "[REQUEST FAILED] #{to_curl}\n"
            raise SearchRequestFailed, @responses.to_s
          end
          @json     = MultiJson.decode(@responses.body)
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
