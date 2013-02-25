require 'test_helper'

module Tire

  class FiltersIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Filters" do

      should "filter the results" do
        # 2.json > Begins with "T" and is tagged "ruby"

        s = Tire.search('articles-test') do
          query { string 'title:T*' }
          filter :terms, :tags => ['ruby']
        end

        assert_equal 1, s.results.count
        assert_equal 'Two', s.results.first.title
      end

      should "filter the results with multiple terms" do
        # 2.json > Is tagged  *both* "ruby" and "python"

        s = Tire.search('articles-test') do
          query { all }
          filter :terms, :tags => ['ruby', 'python'], :execution => 'and'
        end

        assert_equal 1, s.results.count
        assert_equal 'Two', s.results.first.title
      end

      should "filter the results with multiple 'or' filters" do
        # 4.json > Begins with "F" and is tagged "erlang"

        s = Tire.search('articles-test') do
          query { string 'title:F*' }
          filter :or, {:terms => {:tags => ['ruby']}},
                      {:terms => {:tags => ['erlang']}}
        end

        assert_equal 1, s.results.count
        assert_equal 'Four', s.results.first.title
      end

      should "filter the results with multiple 'and' filters" do
        # 5.json > Is tagged ["java", "javascript"] and is published on 2011-01-04

        s = Tire.search('articles-test') do
          filter :terms, :tags         => ["java"]
          filter :term,  :published_on => "2011-01-04"
        end

        assert_equal 1, s.results.count
        assert_equal 'Five', s.results.first.title
      end

      should "not influence facets" do
        s = Tire.search('articles-test') do
          query { string 'title:T*' }
          filter :terms, :tags => ['ruby']

          facet('tags') { terms :tags }
        end

        assert_equal 1, s.results.count
        assert_equal 3, s.results.facets['tags']['terms'].size
      end

    end

  end

end
