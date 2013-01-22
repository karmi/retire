require 'test_helper'

module Tire

  class SortIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Sort" do

      should "sort by title" do
        q = '*'
        s = Tire.search('articles-test') do
          query { string q }
          sort  { by :title }
        end

        assert_equal 5, s.results.count
        assert_equal 'Five', s.results.first[:title]
      end

      should "sort by title, descending" do
        q = '*'
        s = Tire.search('articles-test') do
          query { string q }
          sort  { by :title, :desc }
        end

        assert_equal 5, s.results.count
        assert_equal 'Two', s.results.first[:title]
      end

      should "sort by multiple fields" do
        q = '*'
        s = Tire.search('articles-test') do
          query { string q }
          sort  do
            by :words, :desc
            by :title, :asc
          end
        end

        # p s.results.to_a.map { |i| [i.title, i.sort] }
        assert_equal 'Three', s.results[0][:title]
        assert_equal 'Four',  s.results[1][:title]
        assert_equal 'Two',   s.results[2][:title]
      end

    end

  end

end
