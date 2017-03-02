require 'common_pool'
require 'curb'

module Tire

  module HTTP

    module Client

      class PooledCurbDataSource < CommonPool::PoolDataSource

        def create_object
          Curl::Easy.new
        end

      end

      class PooledCurb

        HTTP_CLIENT_POOL = CommonPool::ObjectPool.new(PooledCurbDataSource.new) { |config| config.max_active = 200 }

        def self.with_client
          curl = HTTP_CLIENT_POOL.borrow_object
          begin
            yield curl
          rescue Curl::Err::MultiBadEasyHandle
            curl = HTTP_CLIENT_POOL.borrow_object
            retry
          ensure
            HTTP_CLIENT_POOL.return_object(curl)
          end
        end

        def self.get(url, data=nil)
          response = nil

          3.times do |tries|
            # Sleep for 0.2 seconds after the second failure
            Kernel.sleep(0.2) if tries > 1

            begin
              response = get_once(url, data)
              if block_given?
                next unless yield response.body, response.code
              else
                next unless response.code == 200 && response.present?
              end

              return response
            rescue Curl::Err::CurlError
              # will retry
            end
          end

          response
        end

        def self.get_once(url, data=nil)
          with_client do |curl|
            curl.timeout = 15
            curl.url = url
            if data
              curl.post_body = data
              curl.http_post
            else
              curl.http_get
            end
            Response.new curl.body_str, curl.response_code
          end
        end

        def self.post(url, data)
          with_client do |curl|
            curl.timeout = 15
            curl.url = url
            curl.post_body = data
            curl.http_post
            Response.new curl.body_str, curl.response_code
          end
        end

        def self.put(url, data)
          with_client do |curl|
            curl.timeout = 15
            curl.url = url
            curl.http_put data
            Response.new curl.body_str, curl.response_code
          end
        end

        def self.delete(url)
          with_client do |curl|
            curl.timeout = 15
            curl.url = url
            curl.http_delete
            Response.new curl.body_str, curl.response_code
          end
        end

        def self.head(url)
          with_client do |curl|
            curl.timeout = 15
            curl.url = url
            curl.http_head
            Response.new curl.body_str, curl.response_code
          end
        end
      end

    end

  end

end
