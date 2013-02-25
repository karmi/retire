require 'test_helper'

module Tire

  class FilteredQueriesIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Filtered queries" do

      should "restrict the results with a filter" do
        # 2.json > Begins with "T" and is tagged "ruby"

        s = Tire.search('articles-test') do
          query do
            filtered do
              query { string 'title:T*' }
              filter :terms, :tags => ['ruby']
            end
          end
        end

        assert_equal 1, s.results.count
        assert_equal 'Two', s.results.first.title
      end

      should "restrict the results with multiple filters, chained with AND by default" do
        # 2.json > Is tagged "ruby" and has 250 words

        s = Tire.search('articles-test') do
          query do
            filtered do
              query { all }
              filter :terms, :tags => ['ruby', 'python']
              filter :range, :words => { :from => '250', :to => '250' }
            end
          end
        end

        assert_equal 1, s.results.count
        assert_equal 'Two', s.results.first.title
      end

      should "restrict the results with multiple OR filters" do
        # 1.json > Is tagged "ruby"
        # 1.json > Is tagged "ruby" and has 250 words
        # 4.json > Has 250 words

        s = Tire.search('articles-test') do
          query do
            filtered do
              query { all }
              filter :or, { :terms => { :tags => ['ruby', 'python'] } },
                          { :range => { :words => { :from => '250', :to => '250' } } }
            end
          end
        end

        assert_equal 3, s.results.count
        assert_equal %w(Four One Two), s.results.map(&:title).sort
      end

    end

  end

end
