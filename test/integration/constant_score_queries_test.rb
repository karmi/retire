require 'test_helper'

module Tire

  class ConstantScoreQueriesIntegrationTest < Test::Unit::TestCase
    include Test::Integration
    context "Constant score queries" do
      context 'with filter' do
        should "return a constant score for all documents even if one document match 'more'" do
          s = Tire.search('articles-test') do
            query do
              constant_score do
                filter :terms, :tags => ['ruby', 'python']
              end
            end
          end

          assert_equal 2, s.results.size
          assert_equal ['One', 'Two'], s.results.map(&:title)

          assert s.results[0]._score > 0
          assert s.results[1]._score > 0
          assert s.results[0]._score == s.results[1]._score
        end
      end

      context 'with query' do
        should "return a constant score for all documents even if one document match more" do
          s = Tire.search('articles-test') do
            query do
              constant_score do
                query do
                  terms :tags, ['ruby', 'python']
                end
              end
            end
          end

          assert_equal 2, s.results.size
          assert_equal ['One', 'Two'], s.results.map(&:title)

          assert s.results[0]._score > 0
          assert s.results[1]._score > 0
          assert s.results[0]._score == s.results[1]._score
        end
      end
    end
  end
end
