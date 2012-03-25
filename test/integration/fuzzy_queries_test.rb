require 'test_helper'

module Tire

  class FuzzyQueryIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Fuzzy query" do
      should "fuzzily find article by tag" do
        results = Tire.search('articles-test') { query { fuzzy :tags, 'irlang' } }.results

        assert_equal 1,        results.count
        assert_equal ["erlang"], results.first[:tags]
      end

    end

  end

end
