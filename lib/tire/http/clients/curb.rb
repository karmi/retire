require 'curb'

module Tire

  module HTTP

    module Client

      class Curb
        def self.client
          Thread.current[:client] ||= begin
            client = ::Curl::Easy.new
            client.resolve_mode = :ipv4
            # client.verbose = true
            client
          end
        end

        def self.get(url, data=nil)
          client.url = url

          # FIXME: Curb cannot post bodies with GET requests?
          #        Roy Fielding seems to approve:
          #        <http://tech.groups.yahoo.com/group/rest-discuss/message/9962>
          if data
            client.post_body = data
            client.http_post
          else
            client.http_get
          end
          Response.new client.body_str, client.response_code
        end

        def self.post(url, data)
          client.url = url
          client.post_body = data
          client.http_post
          Response.new client.body_str, client.response_code
        end

        # NOTE: newrelic_rpm breaks Curl::Easy#http_put
        #       https://github.com/newrelic/rpm/blob/master/lib/new_relic/agent/instrumentation/curb.rb#L49
        #
        def self.put(url, data)
          method = client.respond_to?(:http_put_without_newrelic) ? :http_put_without_newrelic : :http_put
          client.url = url
          client.send method, data
          Response.new client.body_str, client.response_code
        end

        def self.delete(url)
          client.url = url
          client.http_delete
          Response.new client.body_str, client.response_code
        end

        def self.head(url)
          client.url = url
          client.http_head
          Response.new client.body_str, client.response_code
        end

        def self.__host_unreachable_exceptions
          [::Curl::Err::HostResolutionError, ::Curl::Err::ConnectionFailedError]
        end

      end

    end

  end

end
