require 'test_helper'

module Tire

  class CustomScoreQueriesIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Custom score queries" do

      should "allow to define custom score queries (base score on field value)" do
        s = Tire.search('articles-test') do
          query do
            # Give longer documents higher score
            #
            custom_score :script => "1.0 / doc['words'].value" do
              string "title:T*"
            end
          end
        end

        assert_equal 2, s.results.size
        assert_equal ['Two', 'Three'], s.results.map(&:title)

        assert s.results[0]._score > 0
        assert s.results[1]._score > 0
        assert s.results[0]._score > s.results[1]._score
      end

      should "allow to manipulate the default score (boost recent)" do
        s = Tire.search('articles-test') do
          query do
            # Boost recent documents
            #
            custom_score :script => "_score + ( doc['published_on'].date.getMillis() / time() )" do
              string 'title:F*'
            end
          end
        end

        assert_equal 2, s.results.size
        assert_equal ['Five', 'Four'], s.results.map(&:title)

        assert s.results[0]._score > 1
        assert s.results[1]._score > 1
      end

      should "allow to define arbitrary custom scoring" do
        s = Tire.search('articles-test') do
          query do
            # Replace documents score with the count of characters in their title
            #
            custom_score :script => "doc['title'].value.length()" do
              string "title:T*"
            end
          end
        end

        assert_equal 2, s.results.size
        assert_equal ['Three', 'Two'], s.results.map(&:title)

        assert_equal 5.0, s.results.max_score
        assert_equal 5.0, s.results[0]._score
        assert_equal 3.0, s.results[1]._score
      end

      should "allow to pass parameters to the script" do
        s = Tire.search('articles-test') do
          query do
            # Replace documents score with parameterized computation
            #
            custom_score :script => "doc['words'].value.doubleValue() / max(a, b)",
                         :params => { :a => 1, :b => 2 } do
              string "title:T*"
            end
          end
        end

        assert_equal 2, s.results.size
        assert_equal ['Three', 'Two'], s.results.map(&:title)

        assert_equal 187.5, s.results[0]._score
        assert_equal 125.0, s.results[1]._score
      end

    end

  end

end
