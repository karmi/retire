require 'test_helper'

module Tire

  class QueryStringIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Text query" do
      setup do
        Tire.index('articles-test') do
          store :type => 'article', :title => '+1 !!!'
          refresh
        end
      end

      should "find article by title" do
        results = Tire.search('articles-test') { query { text :title, '+1' } }.results

        assert_equal 1,        results.count
        assert_equal "+1 !!!", results.first[:title]
      end

    end

  end

end
