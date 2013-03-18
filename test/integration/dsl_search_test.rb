require 'test_helper'

module Tire

  class DSLSearchIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "DSL" do

      should "allow passing search payload as a Hash" do
        s = Tire.search 'articles-test', :query  => { :query_string => { :query => 'ruby' } },
                                         :facets => { 'tags' => { :filter => { :term => {:tags => 'ruby' } } } }

        assert_equal 2, s.results.count
        assert_equal 2, s.results.facets['tags']['count']
        assert_match %r|articles-test/_search\?pretty' -d '{|, s.to_curl, 'Make sure to ignore payload in URL params'
      end

      should "allow passing URL parameters" do
        s = Tire.search 'articles-test', search_type: 'count', query: { match: { tags: 'ruby' } }

        assert_equal 0, s.results.count
        assert_equal 2, s.results.total
        assert_match %r|articles-test/_search.*search_type=count.*' -d '{|, s.to_curl
      end

      should "allow to pass document type in index name" do
        s = Tire.search 'articles-test/article', query: { match: { tags: 'ruby' } }

        assert_equal 2, s.results.total
        assert_match %r|articles-test/article/_search|, s.to_curl
      end

      should "allow building search query iteratively" do
        s = Tire.search 'articles-test'
        s.query { string 'T*' }
        s.filter :terms, :tags => ['java']

        assert_equal 1, s.results.count
      end

    end

  end

end
