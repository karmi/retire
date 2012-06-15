require 'test_helper'

module Tire

  class FieldQueryIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Searching for field" do

      should "find article by title" do
        q = 'one'
        assert_equal 1, field_query('title', q).results.count
        assert_equal 'One', field_query('title', q).results.first[:title]
      end

      should "find articles by title with boosting" do
        q = 'one^100 OR two'
        assert_equal 2, field_query('title', q).results.count
        assert_equal 'One', field_query('title', q).results.first[:title]
      end

      should "find articles by tags" do
        q = 'ruby AND python'
        assert_equal 1, field_query('tags', q).results.count
        assert_equal 'Two', field_query('tags', q).results.first[:title]
      end

      should "find any article with tags" do
        q = 'ruby OR python OR java'
        assert_equal 4, field_query('tags', q).results.count
      end

      should "pass options to query definition" do
        s = Tire.search 'articles-test' do
          query do
            field 'tags', 'ruby python', :default_operator => 'AND'
          end
        end
        assert_equal 1, s.results.count
      end

    end

    private

    def field_query(fieldname, query)
      Tire.search('articles-test') { query { field fieldname, query } }
    end

  end

end
