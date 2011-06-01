require 'test_helper'

module Tire

  class BooleanQueriesIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Boolean queries" do

      should "allow to set multiple queries per condition" do
        s = Tire.search('articles-test') do
          query do
            boolean do
              must { term :tags, 'ruby' }
              must { term :tags, 'python' }
            end
          end
        end

        assert_equal 1, s.results.size
        assert_equal 'Two', s.results.first.title
      end

      should "allow to set multiple queries for multiple conditions" do
        s = Tire.search('articles-test') do
          query do
            boolean do
              must   { term :tags, 'ruby' }
              should { term :tags, 'python' }
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
