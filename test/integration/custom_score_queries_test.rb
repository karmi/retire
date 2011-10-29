require 'test_helper'

module Tire

  class CustomScoreQueriesIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Custom score queries" do

      should "allow custom score queries" do
        s = Tire.search('articles-test') do
          query do
            custom_score :script => "1 / doc['words'].value" do
              string "title:T*"
            end
          end
        end

        assert_equal 2, s.results.size
        assert_equal ['Two', 'Three'], s.results.map(&:title)
      end
    end

  end

end
