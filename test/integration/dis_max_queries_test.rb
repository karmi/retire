require 'test_helper'

module Tire

  class DisMaxQueriesIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Dis Max queries" do

      should "allow to set multiple conditions" do
        s = Tire.search('articles-test') do 
          query do
            dis_max do
              query { term :tags, 'ruby' }
              query { term :tags, 'python' }
            end
          end
        end

        assert_equal 2, s.results.size
        assert_equal 'Two', s.results[0].title
        assert_equal 'One', s.results[1].title
      end
      
      should "order results by score" do
        s = Tire.search('articles-test') do
          query do
            dis_max do
              query { term :tags, 'ruby' }
              query { term :tags, 'python' }
            end
          end
        end

        assert_equal 2, s.results.size
        assert s.results[0]._score > s.results[1]._score
      end
    end

  end

end
