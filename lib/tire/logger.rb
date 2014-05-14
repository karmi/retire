module Tire
  class Logger

    def initialize(logger, options={})
      @logger = if logger.is_a?(::Logger)
        logger
      else
        ::Logger.new(logger)
      end
      @options = options
    end

    def level
      @options[:level] || 'info'
    end

    def write(message)
      @logger.send(level.to_sym, message)
    end

    def log_request(endpoint, params=nil, curl='')
      # 2001-02-12 18:20:42:32 [_search] (articles,users)
      #
      # curl -X POST ....
      #
      content  = "# #{time}"
      content << " [#{endpoint}]"
      content << " (#{params.inspect})" if params
      content << "\n#\n"
      content << curl
      content << "\n\n"
      write content
    end

    def log_response(status, took=nil, json='')
      # 2001-02-12 18:20:42:32 [200] (4 msec)
      #
      # {
      #   "took" : 4,
      #   "hits" : [...]
      #   ...
      # }
      #
      content  = "# #{time}"
      content << " [#{status}]"
      content << " (#{took} msec)" if took
      content << "\n#\n" unless json.to_s !~ /\S/
      json.to_s.each_line { |line| content << "# #{line}" } unless json.to_s !~ /\S/
      content << "\n\n"
      write content
    end

    def time
      Time.now.strftime('%Y-%m-%d %H:%M:%S:%L')
    end

  end
end
