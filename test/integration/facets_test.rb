require 'test_helper'
require 'date'

module Tire

  class FacetsIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Facets" do

      should "return results scoped to current query" do
        q = 'tags:ruby'
        s = Tire.search('articles-test') do
          query { string q }
          facet 'tags' do
            terms :tags
          end
        end
        facets = s.results.facets['tags']['terms']
        assert_equal 2, facets.count
        assert_equal 'ruby', facets.first['term']
        assert_equal 2,      facets.first['count']
      end

      should "allow to specify global facets and query-scoped facets" do
        q = 'tags:ruby'
        s = Tire.search('articles-test') do
          query { string q }
          facet 'scoped-tags' do
            terms :tags
          end
          facet 'global-tags', :global => true do
            terms :tags
          end
        end

        scoped_facets = s.results.facets['scoped-tags']['terms']
        global_facets = s.results.facets['global-tags']['terms']

        assert_equal 2, scoped_facets.count
        assert_equal 5, global_facets.count
      end

      context "date histogram" do

        should "return aggregated values for all results" do
          s = Tire.search('articles-test') do
            query { all }
            facet 'published_on' do
              date :published_on
            end
          end

          facets = s.results.facets['published_on']['entries']
          assert_equal 4, facets.size, facets.inspect
          assert_equal 2, facets.entries[1]["count"], facets.inspect
        end

      end

      context "date ranges" do

        should "return aggregated values for all results" do
          s = Tire.search('articles-test') do
            query { all }
            facet 'published_on' do
              range :published_on, [{:to => '2010-12-31'}, {:from => '2011-01-01', :to => '2011-01-05'}]
            end
          end

          facets = s.results.facets['published_on']['ranges']
          assert_equal 2, facets.size, facets.inspect
          assert_equal 0, facets.entries[0]["count"], facets.inspect
          assert_equal 5, facets.entries[1]["count"], facets.inspect
        end

      end

    end

  end

end
