require 'test_helper'

module Slingshot

  class SearchTest < Test::Unit::TestCase

    context "Search" do

      should "be initialized with index/indices" do
        assert_raise(ArgumentError) { Search::Search.new }
      end

      should "have the query method" do
        assert_respond_to Search::Search.new('index'), :query
      end

      should "store indices as an array" do
        s = Search::Search.new('index1') do;end
        assert_equal ['index1'], s.indices

        s = Search::Search.new('index1', 'index2') do;end
        assert_equal ['index1', 'index2'], s.indices
      end

      should "return curl snippet for debugging" do
        s = Search::Search.new('index') do
          query { query 'title:foo' }
        end
        assert_equal %q|curl -X POST "http://localhost:9200/index/_search?pretty=true" -d | +
                     %q|'{"query":{"query_string":{"query":"title:foo"}}}'|,
                     s.to_curl
      end

      should "allow chaining" do
        assert_nothing_raised do
          Search::Search.new('index').query { query 'title:foo' }.sort { title 'desc' }.size(5).sort { name 'asc' }.from(1)
        end
      end

      should "perform the search" do
        Configuration.client.expects(:post).returns("{}")
        Results::Collection.expects(:new)
        s = Search::Search.new('index') do
          query { query 'title:foo' }
        end
        s.perform
      end

      context "sort" do

        should "allow sorting by multiple fields" do
          s = Search::Search.new('index') do
            query { query 'foo' }
            sort do
              title 'desc'
              _score
            end
          end
          hash = JSON.load( s.to_json )
          assert_equal [{'title' => 'desc'}, '_score'], hash['sort']
        end
        
      end

      context "facets" do

        should "allow searching for facets" do
          s = Search::Search.new('index') do
            query { query 'title:foo' }
            facet('foo1') { terms :bar, :global => true }
            facet('foo2') { terms :baz }
          end
          assert_equal 2, s.facets.keys.size
          assert_not_nil s.facets['foo1']
          assert_not_nil s.facets['foo2']
        end

      end

      context "with from/size" do

        should "set the values in request" do
          s = Search::Search.new('index') do
            query { query 'foo' }
            size 5
            from 3
          end
          hash = JSON.load( s.to_json )
          assert_equal 5, hash['size']
          assert_equal 3, hash['from']
        end

        should "set the fields limit in request" do
          s = Search::Search.new('index') do
            query { query 'foo' }
            fields :title
          end
          hash = JSON.load( s.to_json )
          assert_equal 'title', hash['fields']
        end

      end

    end

  end

end
