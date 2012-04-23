require 'test_helper'

module Tire
  module Search
    class ScanTest < Test::Unit::TestCase

      context "Scan" do
        setup do
          Configuration.reset
          @results = {
            "_scroll_id" => "abc123",
            "took" => 3,
            "hits" => {
              "total" => 10,
              "hits" => [
                { "_id" => "1", "_source" => { "title" => "Test" } }
              ]
            }
          }
          @empty_results = @results.merge('hits' => {'hits' => []})
          @default_response = mock_response @results.to_json, 200
        end

        should "initialize the search object with the indices" do
          s = Scan.new(['index1', 'index2'])
          assert_instance_of Tire::Search::Search, s.search
        end

        should "fetch the initial scroll ID" do
          s = Scan.new('index1')
          s.search.expects(:perform).
                   returns(stub :json => { '_scroll_id' => 'abc123' })

          assert_equal 'abc123', s.scroll_id
        end

        should "perform the request lazily" do
          s = Scan.new('dummy')

          s.expects(:scroll_id).
            returns('abc123').
            at_least_once

          Configuration.client.expects(:get).
                               with { |url,id| url =~ %r|_search/scroll.*search_type=scan| && id == 'abc123' }.
                               returns(@default_response).
                               once
          
          assert_not_nil s.results
          assert_not_nil s.response
          assert_not_nil s.json
        end

        should "set the total and seen variables" do
          s = Scan.new('dummy')
          s.expects(:scroll_id).returns('abc123').at_least_once
          Configuration.client.expects(:get).returns(@default_response).at_least_once

          assert_equal 10, s.total
          assert_equal 1,  s.seen
        end

        should "log the request and response" do
          Tire.configure { logger STDERR }

          s = Scan.new('dummy')
          s.expects(:scroll_id).returns('abc123').at_least_once
          Configuration.client.expects(:get).returns(@default_response).at_least_once

          Configuration.logger.expects(:log_request).
                               with { |(endpoint, params, curl)| endpoint == 'scroll' }

          Configuration.logger.expects(:log_response).
                               with { |code, took, body| code == 200 && took == 3 && body == '1/10 (10.0%)' }

          s.__perform
        end

        context "results" do
          setup do
            @search = Scan.new('dummy')
            @search.expects(:results).
                    returns(Results::Collection.new @results).
                    then.
                    returns(Results::Collection.new @empty_results).
                    at_least_once
            @search.results
          end

          should "be iterable" do
            assert_respond_to @search, :each
            assert_respond_to @search, :size

            assert_nothing_raised do
              @search.each { |batch| p batch; assert_equal 'Test', batch.first.title }
            end
          end

          should "be iterable by individual documents" do
            assert_respond_to @search, :each_document

            assert_nothing_raised do
              @search.each_document { |item| assert_equal 'Test', item.title }
            end
          end

        end

      end

    end
  end
end
