require 'test_helper'

module Tire::Search

  class QueryTest < Test::Unit::TestCase

    context "Query" do

      should "be serialized to JSON" do
        assert_respond_to Query.new, :to_json
      end

      should "return itself as a Hash" do
        assert_respond_to Query.new, :to_hash
        assert_equal( { :term => { :foo => 'bar' } }, Query.new.term(:foo, 'bar').to_hash )
      end

      should "allow a block to be given" do
        assert_equal( { :term => { :foo => 'bar' } }.to_json, Query.new do
          term(:foo, 'bar')
        end.to_json)
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

      should "allow set default operator when searching with a query string" do
        assert_equal( { :query_string => { :query => 'foo', :default_operator => 'AND' } },
                      Query.new.string('foo', :default_operator => 'AND') )
      end

      should "allow to set options when searching with a query string" do
        assert_equal( { :query_string => { :query => 'foo', :fields => ['title.*'], :use_dis_max => true } },
                      Query.new.string('foo', :fields => ['title.*'], :use_dis_max => true) )
      end

      should "search for all documents" do
        assert_equal( { :match_all => { } }, Query.new.all )
      end

      should "search for documents by IDs" do
        assert_equal( { :ids => { :values => [1, 2], :type => 'foo' }  },
                      Query.new.ids([1, 2], 'foo') )
      end

    end

    context "BooleanQuery" do

      should "raise ArgumentError when no block given" do
        assert_raise(ArgumentError) { Query.new.boolean }
      end

      should "encode options" do
        query = Query.new.boolean(:minimum_number_should_match => 1) do
          must { string 'foo' }
        end

        assert_equal 1, query[:bool][:minimum_number_should_match]
      end

      should "wrap single query" do
        assert_equal( { :bool => {:must => [{ :query_string => { :query => 'foo' } }] }},
                      Query.new.boolean { must { string 'foo' } } )
      end

      should "wrap multiple queries for the same condition" do
        query = Query.new.boolean do
          must { string 'foo' }
          must { string 'bar' }
        end

        assert_equal( 2, query[:bool][:must].size, query[:bool][:must].inspect )
        assert_equal( { :query_string => {:query => 'foo'} }, query[:bool][:must].first )
        assert_equal( { :query_string => {:query => 'bar'} }, query[:bool][:must].last )
      end

      should "wrap queries for multiple conditions" do
        query = Query.new.boolean do
          should   { string 'foo' }
          must     { string 'bar' }
          must     { string 'baz' }
          must_not { string 'fuu' }
        end

        assert_equal 2, query[:bool][:must].size
        assert_equal 1, query[:bool][:should].size
        assert_equal 1, query[:bool][:must_not].size

        assert_equal( { :query_string => {:query => 'foo'} }, query[:bool][:should].first )
        assert_equal( { :query_string => {:query => 'bar'} }, query[:bool][:must].first )
        assert_equal( { :query_string => {:query => 'baz'} }, query[:bool][:must].last )
        assert_equal( { :query_string => {:query => 'fuu'} }, query[:bool][:must_not].first )
      end

    end

  end

end
