require 'test_helper'

module Tire

  class CountIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Count" do

      should "return total number of hits for the query, but no hits" do
        s = Tire.search 'articles-test', :search_type => 'count' do
          query { term :tags, 'ruby' }
        end

        assert_equal 2, s.results.total
        assert_equal 0, s.results.count
        assert s.results.empty?
      end

      should "return facets in results" do
        s = Tire.search 'articles-test', :search_type => 'count' do
          query { term :tags, 'ruby' }
          facet('tags') { terms :tags }
        end

        assert ! s.results.facets['tags'].empty?
        assert_equal 2, s.results.facets['tags']['terms'].select { |t| t['term'] == 'ruby' }.  first['count']
        assert_equal 1, s.results.facets['tags']['terms'].select { |t| t['term'] == 'python' }.first['count']
      end

    end

  end
end
