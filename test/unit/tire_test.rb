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
          payload = { :query => { :query_string => { :query => 'foo' } } }
          Search::Search.expects(:new).with('dummy', :payload => payload).returns( stub(:perform => true) )

          Tire.search 'dummy', payload
        end

        should "allow searching with a JSON string" do
          payload = '{"query":{"query_string":{"query":"foo"}}}'
          Search::Search.expects(:new).with('dummy', :payload => payload).returns( stub(:perform => true) )

          Tire.search 'dummy', payload
        end

        should "raise an error when passed incorrect payload" do
          assert_raise(ArgumentError) do
            Tire.search 'dummy', 1
          end
        end

        should "raise SearchRequestFailed when receiving bad response from backend" do
          assert_raise(Search::SearchRequestFailed) do
            Tire::Configuration.client.expects(:get).returns( mock_response('INDEX DOES NOT EXIST', 404) )
            Tire.search('not-existing', :query => { :query_string => { :query => 'foo' }}).results
          end
        end

        context "when retrieving results" do

          should "not call the #perform method immediately" do
            s = Tire.search('dummy') { query { string 'foo' } }
            s.expects(:perform).never
          end

          should "call #perform from #results" do
            s = Tire.search('dummy') { query { string 'foo' } }
            s.expects(:perform).once
            s.results
          end

        end

        context "when scanning an index" do
          should "initiate the scan" do
            Search::Scan.expects(:new).with { |index| index == 'dummy' }

            Tire.scan('dummy')
          end

          should "allow to pass the query as a block to scan" do
            Search::Scan.expects(:new).with { |index| index == 'dummy' }

            Tire.scan('dummy') { query { string 'foo' } }
          end

          should "allow to pass the query as a hash to scan" do
            payload = { :query => { :query_string => { :query => 'foo' } } }
            Search::Scan.expects(:new).with('dummy', payload)

            Tire.scan 'dummy', payload
          end

        end

      end

      context "utils" do

        should "encode a string for URL" do
          assert_equal 'foo+bar',   Utils.escape('foo bar')
          assert_equal 'foo%2Fbar', Utils.escape('foo/bar')
          assert_equal 'foo%21',    Utils.escape('foo!')
        end

        should "encode a string from URL" do
          assert_equal 'foo bar', Utils.unescape('foo+bar')
          assert_equal 'foo/bar', Utils.unescape('foo%2Fbar')
          assert_equal 'foo!',    Utils.unescape('foo%21')
        end

      end
    end

  end

end
