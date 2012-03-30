module Tire
  module Search

    # http://www.elasticsearch.org/guide/reference/api/search/search-type.html
    # http://www.elasticsearch.org/guide/reference/api/search/scroll.html
    #
    class Scan
      include Enumerable

      attr_reader :indices, :options, :search, :total, :seen

      def initialize(indices=nil, options={}, &block)
        @indices = Array(indices)
        @options = options.update(:search_type => 'scan', :scroll => '10m')
        @seen    = 0
        @search  = Search.new(@indices, @options, &block)
      end

      def url;                Configuration.url + "/_search/scroll";                           end
      def params;             @options.empty? ? '' : '?' + @options.to_param;                  end
      def results;            @results || (__perform; @results);                                 end
      def response;           @response || (__perform; @response);                               end
      def json;               @json || (__perform; @json);                                       end

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

      def __perform
        @response  = Configuration.client.get [url, params].join, scroll_id
        @json      = MultiJson.decode @response.body
        @results   = Results::Collection.new @json, @options
        @total     = @json['hits']['total']
        @seen     += @results.size
        @scroll_id = @json['_scroll_id']
        return self
      ensure
        __logged
      end

      def to_a;        results; end; alias :to_ary :to_a
      def to_curl;     %Q|curl -X GET "#{url}?pretty=true" -d '#{@scroll_id}'|; end

      def __logged(error=nil)
        if Configuration.logger

          Configuration.logger.log_request 'scroll', nil, to_curl

          took = @json['took']        rescue nil
          code = @response.code       rescue nil
          body = "#{@seen}/#{@total}" rescue nil

          Configuration.logger.log_response code || 'N/A', took || 'N/A', body
        end
      end

    end

  end
end
