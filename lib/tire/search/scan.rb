module Tire
  module Search


    # Performs a "scan/scroll" search request, which obtains a `scroll_id`
    # and keeps returning documents matching the passed query (or all documents) in batches.
    #
    # You may want to iterate over the batches being returned:
    #
    #     search = Tire::Search::Scan.new('articles')
    #     search.each do |results|
    #       puts results.map(&:title)
    #     end
    #
    # The scan object has a fully Enumerable-compatible interface, so you may
    # call methods like `map` or `each_with_index` on it.
    #
    # To iterate over individual documents, use the `each_document` method:
    #
    #     search.each_document do |document|
    #       puts document.title
    #     end
    #
    # You may limit the result set being returned by a regular Tire DSL query
    # (or a hash, if you prefer), passed as a second argument:
    #
    #     search = Tire::Search::Scan.new('articles') do
    #       query { term 'author.exact', 'John Smith' }
    #     end
    #
    # The feature is also exposed in the Tire top-level DSL:
    #
    #     search = Tire.scan 'articles' do
    #       query { term 'author.exact', 'John Smith' }
    #     end
    #
    # See Elasticsearch documentation for further reference:
    #
    # * http://www.elasticsearch.org/guide/reference/api/search/search-type.html
    # * http://www.elasticsearch.org/guide/reference/api/search/scroll.html
    #
    class Scan
      include Enumerable

      attr_reader :indices, :options, :search

      def initialize(indices=nil, options={}, &block)
        @indices = Array(indices)
        @options = options.update(:search_type => 'scan', :scroll => '10m')
        @seen    = 0
        @search  = Search.new(@indices, @options, &block)
      end

      def url;                Configuration.url + "/_search/scroll";                           end
      def params;             @options.empty? ? '' : '?' + @options.to_param;                  end
      def results;            @results  || (__perform; @results);                              end
      def response;           @response || (__perform; @response);                             end
      def json;               @json     || (__perform; @json);                                 end
      def total;              @total    || (__perform; @total);                                end
      def seen;               @seen     || (__perform; @seen);                                 end

      def scroll_id
        @scroll_id ||= @search.perform.json['_scroll_id']
      end

      def each
        until results.empty?
          yield results.results
          __perform
        end
      end

      def each_document
        until results.empty?
          results.each { |item| yield item }
          __perform
        end
      end

      def size
        results.size
      end

      def __perform
        @response  = Configuration.client.get [url, params].join, scroll_id
        @json      = MultiJson.decode @response.body
        @results   = Results::Collection.new @json, @options
        @total     = @json['hits']['total'].to_i
        @seen     += @results.size
        @scroll_id = @json['_scroll_id']
        return self
      ensure
        __logged
      end

      def to_a;        results; end; alias :to_ary :to_a
      def to_curl;     %Q|curl -X GET '#{url}?pretty' -d '#{@scroll_id}'|; end

      def __logged(error=nil)
        if Configuration.logger
          Configuration.logger.log_request 'scroll', nil, to_curl

          took = @json['took']        rescue nil
          code = @response.code       rescue nil
          body = "#{@seen}/#{@total} (#{@seen/@total.to_f*100}%)" rescue nil

          Configuration.logger.log_response code || 'N/A', took || 'N/A', body
        end
      end

    end

  end
end
