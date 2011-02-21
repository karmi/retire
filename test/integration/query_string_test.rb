require 'test_helper'

module Slingshot

  class QueryStringIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Searching for query string" do

      should "find article by title" do
        q = 'title:one'
        assert_equal 1, search(q).results.count
        assert_equal 'One', search(q).results.first[:title]
      end

      should "find articles by title with boosting" do
        q = 'title:one^100 OR title:two'
        assert_equal 2, search(q).results.count
        assert_equal 'One', search(q).results.first[:title]
      end

      should "find articles by tags" do
        q = 'tags:ruby AND tags:python'
        assert_equal 1, search(q).results.count
        assert_equal 'Two', search(q).results.first[:title]
      end

      should "find any article with tags" do
        q = 'tags:ruby OR tags:python OR tags:java'
        assert_equal 4, search(q).results.count
      end

    end

    private

    def search(q)
      Slingshot.search('articles-test') { query { string q } }
    end

  end

end
