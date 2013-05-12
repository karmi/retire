require 'test_helper'

module Tire

  class ConstantScoreQueriesIntegrationTest < Test::Unit::TestCase
    include Test::Integration
    context "Constant score queries" do

      should "return the same score for all results" do
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
        assert s.results[0]._score == s.results[1]._score
      end

      context "in the featured results scenario" do
        # Adapted from: http://www.fullscale.co/blog/2013/01/24/Implementing_Featured_Results_With_ElasticSearch.html
        setup do
          @index = Tire.index('featured-results-test') do
            delete
            create
            store title: 'Kitchen special tool',   featured: true
            store title: 'Kitchen tool tool tool', featured: false
            store title: 'Garage tool',            featured: false
            refresh
          end
        end

        teardown do
          @index.delete
        end


        should "return featured results first" do
          s = Tire.search('featured-results-test', search_type: 'dfs_query_then_fetch') do
            query do
              boolean do
                should do
                  constant_score do
                    query  { match :title, 'tool' }
                    filter :term, featured: true
                    boost 100
                  end
                end
                should do
                  match :title, 'tool'
                end
              end
            end
          end

          assert_equal 'Kitchen special tool', s.results[0].title
          assert_equal 'Kitchen tool tool tool', s.results[1].title
        end
      end

    end
  end
end
