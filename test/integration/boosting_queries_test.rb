require 'test_helper'

module Tire

  class BoostingQueriesIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Boosting queries" do

      should "allow to set multiple queries per condition" do
        s = Tire.search('articles-test') do
          query do
            boosting negative_boost: 0.2 do
              positive { string "title:Two title:One tags:ruby tags:python"     }
              negative { term :tags, 'python' }
            end
          end
        end

        assert_equal 'One', s.results[0].title
        assert_equal 'Two', s.results[1].title  # Matches 'python', so is demoted
      end

      context "in the featured results scenario" do
        setup do
          # Tire.configure { logger STDERR }
          @index = Tire.index('featured-results-test') do
            delete; create
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
          s = Tire.search('featured-results-test') do
            query do
              boosting negative_boost: 0.1 do
                positive do
                  match :title, 'tool'
                end
                # The `negative` query runs _within_ the results of the `positive` query,
                # and "rescores" the documents which match it, lowering their score.
                negative do
                  filtered do
                    query  { match :title, 'kitchen' }
                    filter :term, featured: false
                  end
                end
              end
            end
          end

          assert_equal 'Garage tool', s.results[0].title              # Non-kitchen first
          assert_equal 'Kitchen special tool', s.results[1].title     # Featured first
          assert_equal 'Kitchen tool tool tool', s.results[2].title   # Rest
        end
      end

    end

  end

end
