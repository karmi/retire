require 'test_helper'

module Tire

  class BoostingQueriesIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Boosting queries" do

      should "allow to set multiple queries per condition" do
        s = Tire.search('articles-test') do
          query do
            boosting(:negative_boost => 0.2) do
              positive do
                string "Two One"
              end
              negative do
                term :tags, 'python'
              end
            end
          end
        end

        assert_equal 'One', s.results[0].title
        assert_equal 'Two', s.results[1].title
      end

    end

  end

end
