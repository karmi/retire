require 'test_helper'

module Tire

  class DisMaxQueriesIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Boolean queries" do

      should "allow to set multiple queries per condition" do
        s = Tire.search('articles-test') do
          query do
            dis_max do
              query { term :tags, 'ruby' }
              query { term :tags, 'pthon' }
            end
          end
        end

        assert_equal 2, s.results.size
        assert_equal 'One', s.results.first.title
      end

      should "allow to set multiple queries for multiple conditions" do
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

    end

  end

end
