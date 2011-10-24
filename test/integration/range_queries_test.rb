require 'test_helper'

module Tire

  class RangeQueriesIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Range queries" do

      should "allow simple range queries" do
        s = Tire.search('articles-test') do
          query do
            range :words, { :gte => 250 }
          end
        end

        assert_equal 3, s.results.size
        assert_equal ['Two', 'Three', 'Four'].sort, s.results.map(&:title).sort
      end

      should "allow combined range queries" do
        s = Tire.search('articles-test') do
          query do
            range :words, { :gte => 250, :lt => 375 }
          end
        end

        assert_equal 2, s.results.size
        assert_equal ['Two', 'Four'].sort, s.results.map(&:title).sort
      end

    end

  end

end
