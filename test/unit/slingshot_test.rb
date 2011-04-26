require 'test_helper'

module Slingshot

  class SlingshotTest < Test::Unit::TestCase

    context "Slingshot" do

      should "have the DSL methods available" do
        assert_respond_to Slingshot, :search
        assert_respond_to Slingshot, :index
        assert_respond_to Slingshot, :configure
      end

      context "DSL" do

        should "allow searching with a block" do
          Search::Search.expects(:new).returns( stub(:perform => true) )

          Slingshot.search 'dummy' do
            query 'foo'
          end
        end

        should "allow searching with a Ruby Hash" do
          Slingshot::Configuration.client.expects(:post).
            with('http://localhost:9200/dummy/_search','{"query":{"query_string":{"query":"foo"}}}').
            returns( stub(:body => '{}') )
          Slingshot::Results::Collection.expects(:new)

          Slingshot.search 'dummy', :query => { :query_string => { :query => 'foo' }}
        end

        should "allow searching with a JSON string" do
          Slingshot::Configuration.client.expects(:post).
            with('http://localhost:9200/dummy/_search','{"query":{"query_string":{"query":"foo"}}}').
            returns( stub(:body => '{}') )
          Slingshot::Results::Collection.expects(:new)

          Slingshot.search 'dummy', '{"query":{"query_string":{"query":"foo"}}}'
        end

        should "raise an error when passed incorrect payload" do
          assert_raise(ArgumentError) do
            Slingshot.search 'dummy', 1
          end
        end

      end

    end

  end

end
