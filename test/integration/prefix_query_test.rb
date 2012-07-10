require 'test_helper'

module Tire

  class PrefixQueryTest < Test::Unit::TestCase
    include Test::Integration

    context "Prefix queries" do

      should "search by a prefix" do
        s = Tire.search('articles-test') do
          query do
            # "on" => "One"
            prefix :title, "on"
          end
        end

        assert_equal 1, s.results.size
        assert_equal ['One'], s.results.map(&:title)
      end

      should "allow to specify boost" do
        s = Tire.search('articles-test') do
          query do
            boolean do
              # "on" => "One", boost it
              should { prefix :title, "on", :boost => 2.0 }
              should { all }
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
