require 'test_helper'

module Tire

  class QueryStringIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Text query" do
      setup do
        Tire.index('articles-test') do
          store :type => 'article', :title => '+1 !!!'
          store :type => 'article', :title => 'Furry Kitten'
          refresh
        end
      end

      should "find article by title" do
        results = Tire.search('articles-test') do
          query { text :title, '+1' }
        end.results

        assert_equal 1,        results.count
        assert_equal "+1 !!!", results.first[:title]
      end

      should "allow to pass options (fuzziness)" do
        results = Tire.search('articles-test') do
          query { text :title, 'fuzzy mitten', :fuzziness => 0.5, :operator => 'and' }
        end.results

        assert_equal 1,        results.count
        assert_equal "Furry Kitten", results.first[:title]
      end

    end

  end

end
