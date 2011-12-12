require 'test_helper'

module Tire

  class QueryStringIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Searching for query string" do

      should "find article by title" do
        q = 'title:one'
        assert_equal 1, search(q).results.count
        assert_equal 'One', search(q).results.first[:title]
      end
      
      should "find article by free text" do
        q = 'one' 
        assert_equal 1, text('title', q).results.count
        assert_equal 'One', text('title', q).results.first[:title]
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

    def search(q)
      Tire.search('articles-test') { query { string q } }
    end
    
    def text(field, q)
      Tire.search('articles-test') { query { text(field, q) } }
    end

  end

end
