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
                string "two one"
              end
              negative do
                term "tags", "python"
              end
            end
          end
        end

        assert s.results[0]._score > s.results[1]._score
      end

    end

  end

end
