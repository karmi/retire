require 'test_helper'

module Tire

  class FiltersIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Filters" do

      should "filter the results" do
        s = Tire.search('articles-test') do
          query { string 'title:T*' }
          filter :terms, :tags => ['ruby']
        end

        assert_equal 1, s.results.count
        assert_equal 'Two', s.results.first.title
      end

      should "filter the results with multiple filters" do
        s = Tire.search('articles-test') do
          query { string 'title:F*' }
          filter :or, {:terms => {:tags => ['ruby']}},
                      {:terms => {:tags => ['erlang']}}
        end

        assert_equal 1, s.results.count
        assert_equal 'Four', s.results.first.title
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
