module Tire
  module Search


    # Performs a "scroll" search request, which obtains a `scroll_id`
    # and keeps returning documents matching the passed query (or all documents) in batches.
    #
    # You may want to iterate over the batches being returned:
    #
    #     search = Tire::Search::Scroll.new('articles')
    #     search.each do |results|
    #       puts results.map(&:title)
    #     end
    #
    # The scroll object has a fully Enumerable-compatible interface, so you may
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
    #     search = Tire::Search::Scroll.new('articles') do
    #       query { term 'author.exact', 'John Smith' }
    #     end
    #
    # The feature is also exposed in the Tire top-level DSL:
    #
    #     search = Tire.scroll 'articles' do
    #       query { term 'author.exact', 'John Smith' }
    #     end
    #
    # See ElasticSearch documentation for further reference:
    #
    # * http://www.elasticsearch.org/guide/reference/api/search/search-type.html
    # * http://www.elasticsearch.org/guide/reference/api/search/scroll.html
    #
    class Scroll
      include Enumerable

      attr_reader :search, :scroll, :seen

      def initialize(search)
        @search = search
        @seen   = 0
      end

      def url;      Configuration.url + "/_search/scroll"; end
      def params;   "?scroll=#{scroll}"                    end
      def results;  @results  || (perform; @results);      end
      def response; @response || (perform; @response);     end
      def json;     @json     || (perform; @json);         end
      def total;    @total    || (perform; @total);        end

      def scroll
        @search.options[:scroll]
      end

      def scroll_id
        json['_scroll_id']
      end

      def each
        # Scrolling with and without the scan search_type does not act quite in
        # the same way. With scan, ES does not return search results in the
        # first batch of responses. Without scan, ES does. It can be a little
        # confusing. This will probably be corrected in some future ES. See
        # this issue to follow progress on this change.
        #
        # https://github.com/elasticsearch/elasticsearch/issues/2028.
        #
        # So we need to handle both cases in this method. So, grab
        # the first request. If it has any results, it's a traditional scroll,
        # and yield the results. Otherwise, skip the empty results and move
        # onto the next batch.
        if results.size != 0
          yield results.results
        end

        # loop until there are no results left.
        until results.total == @seen do
          perform
          break if results.empty?
          yield results.results
        end
      end

      def each_document
        each do |items|
          items.each { |item| yield item }
        end
      end

      def size
        results.size
      end

      def perform
        if @response.nil?
          @response = @search.response
          @json     = @search.json
          @results  = @search.results
          @seen     = @results.size
          @total    = @results.total
        else
          # Search handles logging the first response.
          begin
            @response  = Configuration.client.get [url, params].join, scroll_id
            @json      = MultiJson.decode @response.body
            @results   = Results::Collection.new @json, @search.options
            @seen     += @results.size
            @total    = @results.total
          ensure
            logged
          end
        end

        return self
      end

      def to_a;        results; end; alias :to_ary :to_a
      def to_curl;     %Q|curl -X GET "#{url}#{params}&pretty=true" -d '#{@scroll_id}'|; end

      def logged(error=nil)
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
