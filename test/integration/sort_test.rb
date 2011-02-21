require 'test_helper'

module Slingshot

  class SortIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Sort" do

      should "sort by title" do
        q = '*'
        s = Slingshot.search('articles-test') do
          query { string q }
          sort  { title }
        end

        assert_equal 5, s.results.count
        assert_equal 'Five', s.results.first[:title]
      end

      should "sort by title, descending" do
        q = '*'
        s = Slingshot.search('articles-test') do
          query { string q }
          sort  { title :desc }
        end

        assert_equal 5, s.results.count
        assert_equal 'Two', s.results.first[:title]
      end

    end

  end

end
