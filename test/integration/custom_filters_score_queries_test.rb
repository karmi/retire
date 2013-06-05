require 'test_helper'

module Tire

  class CustomFiltersScoreQueriesIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Custom filters score queries" do

      should "score the document based on a matching filter" do
        s = Tire.search('articles-test') do
          query do
            custom_filters_score do
              query { all }

              # Give documents over 300 words a score of 3
              filter do
                filter :range, words: { gt: 300 }
                boost 3
              end
            end
          end
        end

        assert_equal 3, s.results[0]._score
        assert_equal 1, s.results[1]._score
      end

      should "allow to use a script based boost factor" do
        s = Tire.search('articles-test') do
          query do
            custom_filters_score do
              query { all }

              # Give documents over 300 words a score of 3
              filter do
                filter :range, words: { gt: 300 }
                script 'doc.words.value * 2'
              end
            end
          end
        end

        # p s.results.to_a.map { |r| [r.title, r.words, r._score] }

        assert_equal 750, s.results[0]._score
        assert_equal 1, s.results[1]._score
      end

      should "allow to define multiple score factors" do
        s = Tire.search('articles-test') do
          query do
            custom_filters_score do
              query { all }

              # The more words a document contains, the more its score is boosted

              filter do
                filter :range, words: { to: 10 }
                boost 1
              end

              filter do
                filter :range, words: { to: 100 }
                boost 2
              end

              filter do
                filter :range, words: { to: 150 }
                boost 3
              end

              filter do
                filter :range, words: { to: 250 }
                boost 5
              end

              filter do
                filter :range, words: { to: 350 }
                boost 7
              end

              filter do
                filter :range, words: { from: 350 }
                boost 10
              end
            end
          end
        end

        # p s.results.to_a.map { |r| [r.title, r.words, r._score] }

        assert_equal 'Three', s.results[0].title
        assert_equal 375, s.results[0].words
        assert_equal 10, s.results[0]._score

        assert_equal 5, s.results[1]._score
        assert_equal 5, s.results[2]._score
        assert_equal 3, s.results[3]._score
        assert_equal 3, s.results[4]._score
      end
    end
  end

end
