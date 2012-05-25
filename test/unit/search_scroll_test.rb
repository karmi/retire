require 'test_helper'

module Tire
  module Search
    class ScrollTest < Test::Unit::TestCase

      context "Scroll" do
        setup do
          Configuration.reset

          @results1 = {
            "_scroll_id" => "abc123",
            "took" => 3,
            "hits" => {
              "total" => 2,
              "hits" => [
                { "_id" => "1", "_source" => { "title" => "Test1" } }
              ]
            }
          }
          @results2 = @results1.merge(
            '_scroll_id' => 'abc124',
            'hits' => {
              "total" => 2,
              'hits' => [
                { "_id" => "2", "_source" => { "title" => "Test2" } }
              ]
            }
          )
          @results3 = @results1.merge(
            '_scroll_id' => 'abc125',
            'hits' => {
              'total' => 2,
              'hits' => []
            }
          )

          @response1 = mock_response @results1.to_json, 200
          @response2 = mock_response @results2.to_json, 200
          @response3 = mock_response @results3.to_json, 200
        end

        should "initialize the search object with the indices" do
          s = Scroll.new(Search.new(['index1', 'index2'], :scroll => '10m'))
          assert_instance_of Tire::Search::Search, s.search
        end

        should "fetch the initial scroll ID" do
          Configuration.client.expects(:get).returns(@response1).once

          s = Scroll.new(Search.new('index1', :scroll => '10m'))

          assert_equal 'abc123', s.scroll_id
        end

        should "perform the request lazily" do
          Configuration.client.expects(:get).never
          Scroll.new(Search.new('dummy', :scroll => '10m'))
        end

        should "perform a search, then a scroll" do
          Configuration.client.expects(:get).returns(@response1).once

          Configuration.client.expects(:get)
                              .with { |url,id| url =~ %r|_search/scroll\?scroll=10m| && id == 'abc123' }
                              .returns(@response2)
                              .once

          Configuration.client.expects(:get)
                              .with { |url,id| url =~ %r|_search/scroll\?scroll=10m| && id == 'abc124' }
                              .returns(@response3)
                              .once

          s = Scroll.new(Search.new('dummy', :scroll => '10m'))

          s.perform
          s.perform
          s.perform
        end

        should "set the total and seen variables" do
          s = Scroll.new(Search.new('dummy', :scroll => '10m'))
          Configuration.client.expects(:get).returns(@response1).once

          assert_equal 2, s.total
          assert_equal 1, s.seen
        end

        should "log the request and response" do
          Tire.configure { logger STDERR }

          Configuration.client.expects(:get).returns(@response1).once

          Configuration.client.expects(:get)
                              .with { |url,id| url =~ %r|_search/scroll\?scroll=10m| && id == 'abc123' }
                              .returns(@response2)
                              .once

          Configuration.client.expects(:get)
                              .with { |url,id| url =~ %r|_search/scroll\?scroll=10m| && id == 'abc124' }
                              .returns(@response3)
                              .once

          Configuration.logger.expects(:log_request).
                               with { |(endpoint, params, curl)| endpoint == '_search' }

          Configuration.logger.expects(:log_response).
                               with { |code, took, body| code == 200 && took == 3 && body == '' }

          Configuration.logger.expects(:log_request).
                               with { |(endpoint, params, curl)| endpoint == 'scroll' }

          Configuration.logger.expects(:log_response).
                               with { |code, took, body| code == 200 && took == 3 && body == '2/2 (100.0%)' }

          Configuration.logger.expects(:log_request).
                               with { |(endpoint, params, curl)| endpoint == 'scroll' }

          Configuration.logger.expects(:log_response).
                               with { |code, took, body| code == 200 && took == 3 && body == '2/2 (100.0%)' }

          s = Scroll.new(Search.new('dummy', :scroll => '10m'))

          s.perform
          s.perform
          s.perform
        end

        context "results" do
          setup do
            @search = Scroll.new(Search.new('dummy', :scroll => '10m'))

            Configuration.client.expects(:get).returns(@response1).once

            Configuration.client.expects(:get)
                                .with { |url,id| url =~ %r|_search/scroll\?scroll=10m| && id == 'abc123' }
                                .returns(@response2)
                                .once

            Configuration.client.expects(:get)
                                .with { |url,id| url =~ %r|_search/scroll\?scroll=10m| && id == 'abc124' }
                                .returns(@response3)
                                .once
          end

          should "be iterable" do
            assert_respond_to @search, :each
            assert_respond_to @search, :size

            batches = []
            assert_nothing_raised do
              @search.each do |batch|
                batches << batch
              end
            end

            assert_equal 2, batches.size

            assert_equal 1, batches[0].size
            assert_equal 'Test1', batches[0].first.title

            assert_equal 1, batches[1].size
            assert_equal 'Test2', batches[1].first.title
          end

          should "be iterable by individual documents" do
            assert_respond_to @search, :each_document

            items = []
            assert_nothing_raised do
              @search.each_document { |item| items << item }
            end

            assert_equal 2, items.size

            assert_equal 'Test1', items[0].title
            assert_equal 'Test2', items[1].title
          end

        end

      end

    end
  end
end
