require 'test_helper'

module Tire

  class TireTest < Test::Unit::TestCase

    context "Tire" do

      should "have the DSL methods available" do
        assert_respond_to Tire, :search
        assert_respond_to Tire, :index
        assert_respond_to Tire, :configure
      end

      context "DSL" do

        should "allow searching with a block" do
          Search::Search.expects(:new).returns( stub(:perform => true) )

          Tire.search 'dummy' do
            query 'foo'
          end
        end

        should "allow searching with a Ruby Hash" do
          Tire::Configuration.client.expects(:post).
            with('http://localhost:9200/dummy/_search','{"query":{"query_string":{"query":"foo"}}}').
            returns( mock_response('{}') )
          Tire::Results::Collection.expects(:new)

          Tire.search 'dummy', :query => { :query_string => { :query => 'foo' }}
        end

        should "allow searching with a JSON string" do
          Tire::Configuration.client.expects(:post).
            with('http://localhost:9200/dummy/_search','{"query":{"query_string":{"query":"foo"}}}').
            returns( mock_response('{}') )
          Tire::Results::Collection.expects(:new)

          Tire.search 'dummy', '{"query":{"query_string":{"query":"foo"}}}'
        end

        should "raise an error when passed incorrect payload" do
          assert_raise(ArgumentError) do
            Tire.search 'dummy', 1
          end
        end

        should "raise SearchRequestFailed when receiving bad response from backend" do
          assert_raise(Search::SearchRequestFailed) do
            Tire::Configuration.client.expects(:post).returns( mock_response('INDEX DOES NOT EXIST', 404) )
            Tire.search 'not-existing', :query => { :query_string => { :query => 'foo' }}
          end
        end

      end

    end

  end

end
