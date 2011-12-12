require 'curb'

module Tire

  module HTTP

    module Client

      class Curb
        @client = ::Curl::Easy.new
        @client.resolve_mode = :ipv4

        # @client.verbose = true

        def self.get(url, data=nil)
          @client.url = url

          # FIXME: Curb cannot post bodies with GET requests?
          #        Roy Fielding seems to approve:
          #        <http://tech.groups.yahoo.com/group/rest-discuss/message/9962>
          if data
            @client.post_body = data
            @client.http_post
          else
            @client.http_get
          end
          Response.new @client.body_str, @client.response_code
        end

        def self.post(url, data)
          @client.url = url
          @client.post_body = data
          @client.http_post
          Response.new @client.body_str, @client.response_code
        end

        def self.put(url, data)
          @client.url = url
          @client.put_data = data
          @client.http_put
          Response.new @client.body_str, @client.response_code
        end

        def self.delete(url)
          @client.url = url
          @client.http_delete
          Response.new @client.body_str, @client.response_code
        end

        def self.head(url)
          @client.url = url
          @client.http_head
          Response.new @client.body_str, @client.response_code
        end

      end

    end

  end

end
