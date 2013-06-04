require 'test_helper'

module Tire

  class CustomFiltersScoreQueriesIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Custom filters score queries" do

      should "allow boosting score based on filters" do
        s = Tire.search('articles-test') do
          query do
            # Give documents over 300 words hight scores
            custom_filters_score do
              query do
                constant_score do
                  query { all}
                  boost 1
                end
              end
              filter({:boost => 3}, :range, :words => {:gt => 300})
            end
          end
        end

        assert_equal 3, s.results[0]._score
        assert_equal 1, s.results[1]._score
      end
    end
  end

end
