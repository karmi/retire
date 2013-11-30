require 'test_helper'

module Tire

  class SuggestIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Search Suggest" do

      should "add suggestions field to the results using the term suggester" do
        # Tire::Configuration.logger STDERR, :level => 'debug'
        s = Tire.search('articles-test') do
          suggest :term_suggest1 do
            text 'thrree'
            term :title
          end
        end

        assert_equal 1, s.results.suggestions.size
        assert_equal 'three', s.results.suggestions.texts.first
      end
    end

    should "add suggestions field to the results using the phrase suggester" do
        # Tire::Configuration.logger STDERR, :level => 'debug'
        s = Tire.search('articles-test') do
          suggest :term_suggest1 do
            text 'thrree'
            phrase :title
          end
        end

        assert_equal 1, s.results.suggestions.size
        assert_equal 'three', s.results.suggestions.texts.first
    end
  end
end