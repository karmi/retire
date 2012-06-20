require 'test_helper'

module Tire::Search

  class QueryTest < Test::Unit::TestCase

    context "Query" do
      should "be serialized to JSON" do
        assert_respond_to Query.new, :to_json
      end

      should "return itself as a Hash" do
        assert_respond_to Query.new, :to_hash
        assert_equal( { :term => { :foo => { :term => 'bar' } } }, Query.new.term(:foo, 'bar').to_hash )
      end

      should "allow a block to be given" do
        assert_equal( { :term => { :foo => { :term => 'bar' } } }.to_json, Query.new do
          term(:foo, 'bar')
        end.to_json)
      end
    end

    context "Term query" do
      should "allow search for single term" do
        assert_equal( { :term => { :foo => { :term => 'bar' } } }, Query.new.term(:foo, 'bar') )
      end

      should "allow search for single term passing an options hash" do
        assert_equal( { :term => { :foo => { :term => 'bar', :boost => 2.0 } } }, Query.new.term(:foo, 'bar', :boost => 2.0) )
      end
    end

    context "Terms query" do
      should "allow search for multiple terms" do
        assert_equal( { :terms => { :foo => ['bar', 'baz'] } }, Query.new.terms(:foo, ['bar', 'baz']) )
      end

      should "allow set minimum match when searching for multiple terms" do
        assert_equal( { :terms => { :foo => ['bar', 'baz'], :minimum_match => 2 } },
                      Query.new.terms(:foo, ['bar', 'baz'], :minimum_match => 2) )
      end
    end

    context "Range query" do
      should "allow search for a range" do
        assert_equal( { :range => { :age => { :gte => 21 } } }, Query.new.range(:age, { :gte => 21 }) )
      end
    end

    context "Text query" do
      should "allow search with a text search" do
        assert_equal( { :text => {'field' => {:query => 'foo'}}}, Query.new.text('field', 'foo'))
      end

      should "allow search with a different operator for text search" do
        assert_equal( { :text => {'field' => {:query => 'foo', :operator => 'and'}}},
                      Query.new.text('field', 'foo', :operator => 'and'))
      end
    end

    context "Query String query" do
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
    end

    context "Custom Score query" do
      should "allow to set script for custom score queries" do
        query = Query.new.custom_score(:script => "_score * doc['price'].value") do
          string 'foo'
        end

        assert_equal "_score * doc['price'].value", query[:custom_score][:script]
      end

      should "allow to pass parameters for custom score queries" do
        query = Query.new.custom_score(:script => "_score * doc['price'].value / max(a, b)",
                                       :params => { :a => 1, :b => 2 }) do
          string 'foo'
        end

        assert_equal 1, query[:custom_score][:params][:a]
        assert_equal 2, query[:custom_score][:params][:b]
      end
    end

    context "Field query" do
      should "allow search with a field string" do
        assert_equal( { :field => { 'title' => { :query => 'foo' } } },
                      Query.new.field('title', 'foo') )
      end

      should "allow set default operator when searching with a field string" do
        assert_equal( { :field => { 'title' => { :query => 'foo', :default_operator => 'AND' } } },
                      Query.new.field('title', 'foo', :default_operator => 'AND') )
      end

      should "allow to set options when searching with a field string" do
        assert_equal( { :field => { 'title' => { :query => 'foo', :boost => 2.0, :use_dis_max => true } } },
                      Query.new.field('title', 'foo', :boost => 2.0, :use_dis_max => true) )
      end
    end

    context "All query" do
      should "search for all documents" do
        assert_equal( { :match_all => { } }, Query.new.all )
      end
    end

    context "IDs query" do
      should "search for documents by IDs" do
        assert_equal( { :ids => { :values => [1, 2], :type => 'foo' }  },
                      Query.new.ids([1, 2], 'foo') )
      end
    end
    
    context "FuzzyQuery" do

      should "allow a fuzzy search" do
        assert_equal( { :fuzzy => { :foo => { :term => 'bar' } } }, Query.new.fuzzy(:foo, 'bar') )
      end

      should "allow a fuzzy search with an options hash" do
        assert_equal( { :term => { :foo => { :term => 'bar', :boost => 1.0, :min_similarity => 0.5 } } }, Query.new.term(:foo, 'bar', :boost => 1.0, :min_similarity => 0.5 ) )
      end

    end

    context "BooleanQuery" do

      should "not raise an error when no block is given" do
        assert_nothing_raised { Query.new.boolean }
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

      should "allow passing variables from outer scope" do
        @q1 = 'foo'
        @q2 = 'bar'
        query = Query.new.boolean do |boolean|
          boolean.must { |query| query.string @q1 }
          boolean.must { |query| query.string @q2 }
        end

        assert_equal( 2, query[:bool][:must].size, query[:bool][:must].inspect )
        assert_equal( { :query_string => {:query => 'foo'} }, query[:bool][:must].first )
        assert_equal( { :query_string => {:query => 'bar'} }, query[:bool][:must].last )
      end

    end

    context "FilteredQuery" do

      should "not raise an error when no block is given" do
        assert_nothing_raised { Query.new.filtered }
      end

      should "properly encode filter" do
        query = Query.new.filtered do
          query { term :foo, 'bar' }
          filter :terms, :tags => ['ruby']
        end

        query[:filtered].tap do |f|
          assert_equal( { :term => { :foo => { :term => 'bar' } } }, f[:query].to_hash )
          assert_equal( { :tags => ['ruby'] }, f[:filter][:and].first[:terms] )
        end
      end

      should "properly encode multiple filters" do
        query = Query.new.filtered do
          query { term :foo, 'bar' }
          filter :terms, :tags => ['ruby']
          filter :terms, :tags => ['python']
        end

        query[:filtered][:filter].tap do |filter|
          assert_equal 1, filter.size
          assert_equal( { :tags => ['ruby'] },   filter[:and].first[:terms] )
          assert_equal( { :tags => ['python'] }, filter[:and].last[:terms] )
        end
      end

      should "allow passing variables from outer scope" do
        @my_query  = 'bar'
        @my_filter = { :tags => ['ruby'] }

        query = Query.new.filtered do |f|
          f.query { |q| q.term :foo, @my_query }
          f.filter :terms, @my_filter
        end

        query[:filtered].tap do |f|
          assert_equal( { :term => { :foo => { :term => 'bar' } } }, f[:query].to_hash )
          assert_equal( { :tags => ['ruby'] }, f[:filter][:and].first[:terms] )
        end
      end

      context "Prefix query" do
        should "allow search for a prefix" do
          assert_equal( { :prefix => { :user => "foo" } }, Query.new.prefix(:user, "foo") )
        end

        should "allow setting boost for prefix" do
          assert_equal( { :prefix => {:user => {:prefix => "foo", :boost => 2.0 } } },
                        Query.new.prefix(:user, "foo", :boost => 2.0) )
        end
      end

    end
  end

end
