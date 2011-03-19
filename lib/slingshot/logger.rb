module Slingshot
  class Logger

    def initialize(device, options={})
      @device = if device.respond_to?(:write)
        device
      else
        File.open(device, 'a')
      end
      @options = options
      at_exit { @device.close unless @device.closed? }
    end

    def level
      @options[:level] || 'info'
    end

    def write(message)
      @device.write message
    end

    def log_request(endpoint, params=nil, curl='')
      # [_search] (articles,users) 2001-02-12 18:20:42:32
      #
      # curl -X POST ....
      #
      content  = "# [#{endpoint}] "
      content += "(#{params.inspect}) " if params
      content += time
      content += "\n#\n"
      content += curl
      content += "\n\n"
      write content
    end

    def log_response(status, json)
      # [200 OK] (4 msec) Sat Feb 12 19:20:47 2011
      #
      # {
      #   "took" : 4,
      #   "hits" : [...]
      #   ...
      # }
      #
      took = JSON.parse(json)['took'] rescue nil
      content  = "# [#{status}] "
      content += "(#{took} msec) " if took
      content += time
      content += "\n#\n"
      json.each_line { |line| content += "# #{line}" }
      content += "\n\n"
      write content
    end

    def time
      Time.now.strftime('%Y-%m-%d %H:%M:%S:%L')
    end

  end
end
