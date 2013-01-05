require 'test_helper'

module Tire
  class CountTest < Test::Unit::TestCase

    context "Count" do
      setup { Configuration.reset }

      should "be initialized with single index" do
        c = Search::Count.new('index')
        assert_equal ['index'], c.indices
        assert_match %r|/index/_count|, c.url
      end

      should "count all documents by the leaving index empty" do
        c = Search::Count.new
        assert c.indices.empty?, "#{c.indices.inspect} should be empty"
        assert_match %r|localhost:9200/_count|, c.url
      end

      should "limit count with document type" do
        c = Search::Count.new('index', :type => 'bar')
        assert_equal ['bar'], c.types
        assert_match %r|index/bar/_count|, c.url
      end

      should "pass URL parameters" do
        c = Search::Count.new('index', :routing => 123)
        assert  ! c.params.empty?
        assert_match %r|routing=123|, c.params
      end

      should "evaluate the query" do
        Search::Query.any_instance.expects(:instance_eval)

        c = Search::Count.new('index') { string 'foo' }
        assert_not_nil c.query
      end

      should "allow access to the JSON and the response" do
        Configuration.client.expects(:get).returns(mock_response( '{"count":1}', 200 ))
        c = Search::Count.new('index')
        c.perform
        assert_equal 1, c.json['count']
        assert_equal 200, c.response.code
      end

      should "return curl snippet for debugging" do
        c = Search::Count.new('index') { term :title, 'foo' }
        assert_match %r|curl \-X GET 'http://localhost:9200/index/_count\?pretty' -d |, c.to_curl
        assert_match %r|"term"\s*:\s*"foo"|, c.to_curl
      end

      should "log the request when logger is set" do
        Configuration.logger STDERR

        Configuration.client.expects(:get).returns(mock_response( '{"count":1}', 200 ))
        Configuration.logger.expects(:log_request).returns(true)
        Configuration.logger.expects(:log_response).returns(true)

        Search::Count.new('index').value
      end

    end

  end
end
