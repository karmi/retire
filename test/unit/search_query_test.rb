require 'test_helper'

module Slingshot::Search

  class QueryTest < Test::Unit::TestCase

    context "Query" do

      should "be serialized to JSON" do
        assert_respond_to Query.new, :to_json
      end

      should "allow search for single term" do
        assert_equal( { :term => { :foo => 'bar' } }, Query.new.term(:foo, 'bar') )
      end

      should "allow search for multiple terms" do
        assert_equal( { :terms => { :foo => ['bar', 'baz'] } }, Query.new.terms(:foo, ['bar', 'baz']) )
      end

      should "allow set minimum match when searching for multiple terms" do
        assert_equal( { :terms => { :foo => ['bar', 'baz'], :minimum_match => 2 } },
                      Query.new.terms(:foo, ['bar', 'baz'], :minimum_match => 2) )
      end

      should "allow search with a query string" do
        assert_equal( { :query_string => { :query => 'title:foo' } },
                      Query.new.string('title:foo') )
      end

      should "allow set default field when searching with a query string" do
        assert_equal( { :query_string => { :query => 'foo', :default_field => 'title' } },
                      Query.new.string('foo', :default_field => 'title') )
      end

      should "search for all documents" do
        assert_equal( { :match_all => { } }, Query.new.all )
      end

    end

  end

end
