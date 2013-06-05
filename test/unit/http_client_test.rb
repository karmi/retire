require 'test_helper'

module Tire
  module HTTP

    class ClientTest < Test::Unit::TestCase

      context "RestClient" do

        should "be default" do
          assert_equal Client::RestClient, Configuration.client
        end

        should "respond to HTTP methods" do
          assert_respond_to Client::RestClient, :get
          assert_respond_to Client::RestClient, :post
          assert_respond_to Client::RestClient, :put
          assert_respond_to Client::RestClient, :delete
          assert_respond_to Client::RestClient, :head
        end

        should "not rescue generic exceptions" do
          Client::RestClient.expects(:get).raises(RuntimeError, "Something bad happened in YOUR code")

          assert_raise(RuntimeError) do
            Client::RestClient.get 'http://example.com'
          end
        end

        should "not rescue ServerBrokeConnection errors" do
          Client::RestClient.expects(:get).raises(RestClient::ServerBrokeConnection)

          assert_raise(RestClient::ServerBrokeConnection) do
            Client::RestClient.get 'http://example.com'
          end
        end

        should "not rescue RequestTimeout errors" do
          Client::RestClient.expects(:get).raises(RestClient::RequestTimeout)

          assert_raise(RestClient::RequestTimeout) do
            Client::RestClient.get 'http://example.com'
          end
        end

        should "have __host_unreachable_exceptions" do
          assert_respond_to Client::RestClient, :__host_unreachable_exceptions
        end

      end

      if defined?(Curl)
        require 'tire/http/clients/curb'

        context "Curb" do
          setup do
            Configuration.client Client::Curb
          end

          teardown do
            Configuration.client Client::RestClient
          end

          should "use POST method if request body passed" do
            ::Curl::Easy.any_instance.expects(:http_post)

            response = Configuration.client.get "http://localhost:3000", '{ "query_string" : { "query" : "apple" }}'
          end

          should "use GET method if request body is nil" do
            ::Curl::Easy.any_instance.expects(:http_get)

            response = Configuration.client.get "http://localhost:9200/articles/article/1"
          end

          should "be threadsafe" do
            threads = []

            %w| foo bar |.each do |q|
              threads << Thread.new do
                Tire.search { query { match :_all, q } }.results.to_a
              end
            end

            threads.each { |t| t.join() }
          end

          should "have __host_unreachable_exceptions" do
            assert_respond_to Client::RestClient, :__host_unreachable_exceptions
          end

        end

      end

    end
  end

end
