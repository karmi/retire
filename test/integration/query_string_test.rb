require 'test_helper'

module Tire

  class QueryStringIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Searching for query string" do

      should "find article by title" do
        q = 'title:one'
        assert_equal 1, string_query(q).results.count
        assert_equal 'One', string_query(q).results.first[:title]
      end

      should "find articles by title with boosting" do
        q = 'title:one^100 OR title:two'
        assert_equal 2, string_query(q).results.count
        assert_equal 'One', string_query(q).results.first[:title]
      end

      should "find articles by tags" do
        q = 'tags:ruby AND tags:python'
        assert_equal 1, string_query(q).results.count
        assert_equal 'Two', string_query(q).results.first[:title]
      end

      should "find any article with tags" do
        q = 'tags:ruby OR tags:python OR tags:java'
        assert_equal 4, string_query(q).results.count
      end

      should "pass options to query definition" do
        s = Tire.search 'articles-test' do
          query do
            string 'ruby python', :default_operator => 'AND'
          end
        end
        assert_equal 1, s.results.count
      end

    end

    private

    def string_query(q)
      Tire.search('articles-test') { query { string q } }
    end

  end

end
