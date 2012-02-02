require 'test_helper'

module Tire

  class PrefixQueryTest < Test::Unit::TestCase
    include Test::Integration

    context "Prefix queries" do

      should "allow simple prefix queries" do
        s = Tire.search('articles-test') do
          query do
            prefix :title, "on" 
          end
        end

        assert_equal 1, s.results.size
        assert_equal ['One'], s.results.map(&:title)
      end
      
      should "allow boost specifying" do
        s = Tire.search('articles-test') do
          query do
            boolean do
              should { prefix :title, "on", :boost => 2.0 }
              should { range :words, { :gte => 5 } }
            end
          end
          sort { by :_score }
        end
        
        assert_equal 5, s.results.size
        assert_equal 'One', s.results.first.title
      
      end

    end

  end

end
