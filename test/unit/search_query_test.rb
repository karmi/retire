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

      should "have accessor for value" do
        assert_equal( {}, Query.new.value )
      end
    end

    context "Term query" do
      should "allow search for single term" do
        assert_equal( { :term => { :foo => { :term => 'bar' } } }, Query.new.term(:foo, 'bar') )
      end

      should "allow search for single term passing an options hash" do
        assert_equal( { :term => { :foo => { :term => 'bar', :boost => 2.0 } } }, Query.new.term(:foo, 'bar', :boost => 2.0) )
      end

      should "allow complex term queries" do
        assert_equal( { :term => { :foo => { :field => 'bar', :boost => 2.0 } } }, Query.new.term(:foo, {:field => 'bar', :boost => 2.0}) )
      end

      should "allow complex term queries with Hash-like objects" do
        assert_equal(
          { :term => { :foo => { :field => 'bar', :boost => 2.0 } } },
          Query.new.term(:foo, Hashr.new( :field => 'bar', :boost => 2.0 ))
        )
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

      should "allow set boost when searching for multiple terms" do
        assert_equal( { :terms => { :foo => ['bar', 'baz'], :boost => 2 } },
                      Query.new.terms(:foo, ['bar', 'baz'], :boost => 2) )
      end
    end

    context "Range query" do
      should "allow search for a range" do
        assert_equal( { :range => { :age => { :gte => 21 } } }, Query.new.range(:age, { :gte => 21 }) )
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

    context 'CustomFiltersScoreQuery' do
      should "not raise an error when no block is given" do
        assert_nothing_raised { Query.new.custom_filters_score }
      end

      should "provides a default filter if no filter is given" do
        query = Query.new.custom_filters_score do
          query { term :foo, 'bar' }
        end

        f = query[:custom_filters_score]

        assert_equal( { :term => { :foo => { :term => 'bar' } } }, f[:query].to_hash )
        assert_equal( { :match_all => {} }, f[:filters].first[:filter])
        assert_equal( 1.0, f[:filters].first[:boost])
      end

      should "properly encode filter with boost" do
        query = Query.new.custom_filters_score do
          query { term :foo, 'bar' }
          filter do
            filter :terms, :tags => ['ruby']
            boost 2.0
          end
        end

        f = query[:custom_filters_score]

        assert_equal( { :term => { :foo => { :term => 'bar' } } }, f[:query].to_hash )
        assert_equal( { :tags => ['ruby'] }, f[:filters].first[:filter][:terms])
        assert_equal( 2.0, f[:filters].first[:boost])
      end

      should "properly encode filter with script" do
        query = Query.new.custom_filters_score do
          query { term :foo, 'bar' }
          filter do
            filter :terms, :tags => ['ruby']
            script '2.0'
          end
        end

        f = query[:custom_filters_score]

        assert_equal( { :term => { :foo => { :term => 'bar' } } }, f[:query].to_hash )
        assert_equal( { :tags => ['ruby'] }, f[:filters].first[:filter][:terms])
        assert_equal( '2.0', f[:filters].first[:script])
      end

      should "properly encode multiple filters" do
        query = Query.new.custom_filters_score do
          query { term :foo, 'bar' }
          filter do
            filter :terms, :tags => ['ruby']
            boost 2.0
          end
          filter do
            filter :terms, :tags => ['python']
            script '2.0'
          end
        end

        f = query[:custom_filters_score]

        assert_equal( { :term => { :foo => { :term => 'bar' } } }, f[:query].to_hash )
        assert_equal( { :tags => ['ruby'] }, f[:filters].first[:filter][:terms])
        assert_equal( 2.0, f[:filters].first[:boost])
        assert_equal( { :tags => ['python'] }, f[:filters].last[:filter][:terms])
        assert_equal( '2.0', f[:filters].last[:script])
      end

      should "allow setting the score_mode" do
        query = Query.new.custom_filters_score do
          query { term :foo, 'bar' }
          score_mode 'total'
        end

        f = query[:custom_filters_score]

        assert_equal( { :term => { :foo => { :term => 'bar' } } }, f[:query].to_hash )
        assert_equal( 'total', f[:score_mode])
      end

      should "allow setting params" do
        query = Query.new.custom_filters_score do
          query { term :foo, 'bar' }
          params :a => 'b'
        end

        f = query[:custom_filters_score]

        assert_equal( { :term => { :foo => { :term => 'bar' } } }, f[:query].to_hash )
        assert_equal( { :a => 'b' }, f[:params] )
      end

      should "allow using script parameters" do
        score_script = "foo * 2"

        query = Query.new.custom_filters_score do
          query { string 'foo' }

          params :foo => 42

          filter do
            filter :exists, :field => 'date'
            script score_script
          end
        end

        f = query[:custom_filters_score]

        assert_equal 42, f[:params][:foo]
      end
    end

    context "All query" do
      should "search for all documents" do
        assert_equal( { :match_all => { } }, Query.new.all )
      end

      should "allow passing arguments" do
        assert_equal( { :match_all => {:boost => 1.2} }, Query.new.all(:boost => 1.2) )
      end
    end

    context "IDs query" do
      should "search for documents by IDs" do
        assert_equal( { :ids => { :values => [1, 2] }  },
                      Query.new.ids([1, 2]) )
      end
      should "search for documents by IDs and type" do
        assert_equal( { :ids => { :values => [1, 2], :type => 'foo' }  },
                      Query.new.ids([1, 2], 'foo') )
      end
      should "convert argument to Array" do
        assert_equal( { :ids => { :values => [1] }  },
                      Query.new.ids(1) )
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

    context "DisMaxQuery" do

      should "not raise an error when no block is given" do
        assert_nothing_raised { Query.new.dis_max }
      end

      should "encode options" do
        query = Query.new.dis_max(:tie_breaker => 0.7) do
          query { string 'foo' }
        end

        assert_equal 0.7, query[:dis_max][:tie_breaker]
      end

      should "wrap single query" do
        assert_equal( { :dis_max => {:queries => [{ :query_string => { :query => 'foo' } }] }},
                      Query.new.dis_max { query { string 'foo' } } )
      end

      should "wrap multiple queries" do
        query = Query.new.dis_max do
          query   { string 'foo' }
          query   { string 'bar' }
          query   { string 'baz' }
        end

        assert_equal 3, query[:dis_max][:queries].size

        assert_equal( { :query_string => {:query => 'foo'} }, query[:dis_max][:queries][0] )
        assert_equal( { :query_string => {:query => 'bar'} }, query[:dis_max][:queries][1] )
        assert_equal( { :query_string => {:query => 'baz'} }, query[:dis_max][:queries][2] )
      end

      should "allow passing variables from outer scope" do
        @q1 = 'foo'
        @q2 = 'bar'
        query = Query.new.dis_max do |dis_max|
          dis_max.query { |query| query.string @q1 }
          dis_max.query { |query| query.string @q2 }
        end

        assert_equal( 2, query[:dis_max][:queries].size, query[:dis_max][:queries].inspect )
        assert_equal( { :query_string => {:query => 'foo'} }, query[:dis_max][:queries].first )
        assert_equal( { :query_string => {:query => 'bar'} }, query[:dis_max][:queries].last )
      end

    end

    context "BoostingQuery" do

      should "not raise an error when no block is given" do
        assert_nothing_raised { Query.new.boosting }
      end

      should "encode options" do
        query = Query.new.boosting(:negative_boost => 0.2) do
          positive { string 'foo' }
        end

        assert_equal 0.2, query[:boosting][:negative_boost]
      end

      should "wrap positive query" do
        assert_equal( { :boosting => {:positive => [{ :query_string => { :query => 'foo' } }] }},
                      Query.new.boosting { positive { string 'foo' } } )
      end

      should "wrap negative query" do
        assert_equal( { :boosting => {:negative => [{ :query_string => { :query => 'foo' } }] }},
                      Query.new.boosting { negative { string 'foo' } } )
      end

      should "wrap multiple queries for the same condition" do
        query = Query.new.boosting do
          positive { string 'foo' }
          positive { term('bar', 'baz') }
        end

        assert_equal( 2, query[:boosting][:positive].size, query[:boosting][:positive].inspect )
        assert_equal( { :query_string => {:query => 'foo'} }, query[:boosting][:positive].first )
        assert_equal( { :term => { "bar" => { :term => "baz" } } }, query[:boosting][:positive].last )
      end

      should "allow passing variables from outer scope" do
        @q1 = 'foo'
        @q2 = 'bar'
        query = Query.new.boosting do |boosting|
          boosting.positive { |query| query.string @q1 }
          boosting.negative { |query| query.string @q2 }
        end

        assert_equal( { :query_string => {:query => 'foo'} }, query[:boosting][:positive].first )
        assert_equal( { :query_string => {:query => 'bar'} }, query[:boosting][:negative].last )
      end

    end

    context "MatchQuery" do

      should "allow searching in single field" do
        assert_equal( { :match => { :foo => { :query => 'bar' } } },
                      Query.new.match(:foo, 'bar') )
      end

      should "allow searching in multiple fields with multi_match" do
        assert_equal( { :multi_match => { :query => 'bar', :fields => [:foo, :moo] } },
                      Query.new.match([:foo, :moo], 'bar') )
      end

      should "encode options" do
        query = Query.new.match(:foo, 'bar', :type => 'phrase_prefix')
        assert_equal 'phrase_prefix', query[:match][:foo][:type]
      end

      should "automatically construct a boolean query" do
        query = Query.new
        query.match(:foo, 'bar')
        query.match(:moo, 'bar')

        assert_not_nil  query.to_hash[:bool]
        assert_equal 2, query.to_hash[:bool][:must].size
      end

    end

    context "NestedQuery" do

      should "not raise an error when no block is given" do
        assert_nothing_raised { Query.new.nested }
      end

      should "encode options" do
        query = Query.new.nested(:path => 'articles', :score_mode => 'score_mode') do
          query { string 'foo' }
        end

        assert_equal 'articles',   query[:nested][:path]
        assert_equal 'score_mode', query[:nested][:score_mode]
      end

      should "wrap single query" do
        assert_equal( { :nested => {:query => { :query_string => { :query => 'foo' } } }},
                      Query.new.nested { query { string 'foo' } } )
      end

    end

    context 'ConstantScoreQuery' do
      should "not raise an error when no block is given" do
        assert_nothing_raised { Query.new.constant_score }
      end

      should "wrap query" do
        assert_equal( { :constant_score => {:query => { :term => { :attr => { :term => 'foo' } } } } },
                      Query.new.constant_score { query { term :attr, 'foo' } } )
      end

      should "wrap multiple filters" do
        assert_equal( { :constant_score => {:filter => {:and => [ { :term => { :attr => 'foo' } }, { :term => { :attr => 'bar' } } ] } } },
                      Query.new.constant_score do
                        filter :term, :attr => 'foo'
                        filter :term, :attr => 'bar'
                      end )
      end

      should "wrap the boost" do
        assert_equal( { :constant_score => {:boost => 3 } },
                      Query.new.constant_score { boost 3 } )
      end

    end

  end
end
