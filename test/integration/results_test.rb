require 'test_helper'

module Tire

  class ResultsIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Query results" do

      should "allow easy access to returned documents" do
        q = 'title:one'
        s = Tire.search('articles-test') { query { string q } }
        assert_equal 'One',  s.results.first.title
        assert_equal 'ruby', s.results.first.tags[0]
      end

      should "allow easy access to returned documents with limited fields" do
        q = 'title:one'
        s = Tire.search('articles-test') { query { string q }.fields :title }
        assert_equal 'One', s.results.first.title
        assert_nil s.results.first.tags
      end

      should "allow to retrieve multiple fields" do
        q = 'title:one'
        s = Tire.search('articles-test') do
          query { string q }
          fields 'title', 'tags'
        end
        assert_equal 'One',  s.results.first.title
        assert_equal 'ruby', s.results.first.tags[0]
        assert_nil s.results.first.published_on
      end

    end

    should "iterate with hits" do
      q = 'title:one'
      s = Tire.search('articles-test') { query { string q }.fields :title }

      s.results.each_with_hit do |result, hit|
        assert_equal 'One',  result.title

        assert_equal 'articles-test', hit['_index']
        assert_equal 'article', hit['_type']
        assert ((0.3)..(0.4)).include?(hit['_score']), "not in range"

        assert_equal "1", hit['_id']
        assert_equal 'One', hit['fields']['title']
      end

    end
  end

end
