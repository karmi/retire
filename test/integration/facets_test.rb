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
          facet('scoped-tags')                  { terms :tags }
          facet('global-tags', :global => true) { terms :tags }
        end

        scoped_facets = s.results.facets['scoped-tags']['terms']
        global_facets = s.results.facets['global-tags']['terms']

        assert_equal 2, scoped_facets.count
        assert_equal 5, global_facets.count
      end

      should "allow to define multiple facets" do
        s = Tire.search('articles-test') do
          facet('tags') { terms :tags }
          facet('date') { date :published_on }
        end

        assert_equal 2, s.results.facets.size
      end

      should "allow to restrict facets with filters" do
        s = Tire.search('articles-test') do
          query { string 'tags:ruby' }
          facet('tags', :facet_filter => { :range => { :published_on => { :from => '2011-01-01', :to => '2011-01-01' } }  }) do
            terms :tags
          end
        end

        assert_equal 1,      s.results.facets.size
        assert_equal 'ruby', s.results.facets['tags']['terms'].first['term']
        assert_equal 1,      s.results.facets['tags']['terms'].first['count'].to_i
      end

      should "allow to define the facet filter with DSL" do
          s = Tire.search('articles-test', :search_type => 'count') do
            facet 'tags' do
              terms :tags
              facet_filter :range, { :published_on => { :from => '2011-01-01', :to => '2011-01-01' } }
            end
          end

          assert_equal 1,      s.results.facets.size
          assert_equal 'ruby', s.results.facets['tags']['terms'].first['term']
          assert_equal 1,      s.results.facets['tags']['terms'].first['count'].to_i
      end

      should "allow arbitrary order of methods in the DSL block" do
          s = Tire.search('articles-test', :search_type => 'count') do
            facet 'tags' do
              facet_filter :range, { :published_on => { :from => '2011-01-01', :to => '2011-01-01' } }
              terms :tags
            end
          end

          assert_equal 1,      s.results.facets.size
          assert_equal 'ruby', s.results.facets['tags']['terms'].first['term']
          assert_equal 1,      s.results.facets['tags']['terms'].first['count'].to_i
      end

      context "terms" do
        setup do
          @s = Tire.search('articles-test') do
            query { string 'tags:ruby' }
          end
        end

        should "return results ordered by term" do
          @s.facet('tags')              { terms :tags                }
          @s.facet('term-ordered-tags') { terms :tags, order: 'term' }

          facets = @s.results.facets
          # p facets
          assert_equal 'ruby',   facets['tags']['terms']             .first['term']
          assert_equal 'python', facets['term-ordered-tags']['terms'].first['term']
        end

        should "return results aggregated over multiple fields" do
          @s.facet('multiple-fields') { terms ['tags', 'words'] }

          facets = @s.results.facets
          # p facets
          assert_equal 4, facets['multiple-fields']['terms'].size
        end

      end

      context "date histogram" do

        should "return aggregated counts for each bucket" do
          s = Tire.search('articles-test') do
            query { all }
            facet 'published_on' do
              date :published_on
            end
          end

          facets = s.results.facets['published_on']['entries']
          assert_equal 4, facets.size, facets.inspect
          assert_equal 2, facets.entries[1]['count'], facets.inspect
        end

        should "return value statistics for each bucket" do
          s = Tire.search('articles-test', search_type: 'count') do
            query { all }
            facet 'published_on' do
              date :published_on, value_field: 'words'
            end
          end

          facets = s.results.facets['published_on']['entries']
          assert_equal 4, facets.size, facets.inspect
          assert_equal 2, facets.entries[1]['count'], facets.inspect
          assert_equal 625.0, facets.entries[1]['total'], facets.inspect
        end

        should "return value statistics for each bucket by script" do
          s = Tire.search('articles-test', search_type: 'count') do
            query { all }
            facet 'published_on' do
              date :published_on, value_script: "doc.title.value.length()"
            end
          end

          facets = s.results.facets['published_on']['entries']
          assert_equal 4, facets.size, facets.inspect
          assert_equal 2, facets.entries[1]['count'], facets.inspect
          assert_equal 8.0, facets.entries[1]['total'], facets.inspect # Two + Three => 8 characters
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

      context "histogram" do

        should "return aggregated values for all results" do
          s = Tire.search('articles-test') do
            query { all }
            facet 'words_histogram' do
              histogram :words, :interval => 100
            end
          end

          facets = s.results.facets['words_histogram']['entries']
          assert_equal 3, facets.size, facets.inspect
          assert_equal({"key" => 100, "count" => 2}, facets.entries[0], facets.inspect)
          assert_equal({"key" => 200, "count" => 2}, facets.entries[1], facets.inspect)
          assert_equal({"key" => 300, "count" => 1}, facets.entries[2], facets.inspect)
        end

      end

      context "geo distance" do
        setup do
          @index = Tire.index('bars-test') do
            delete
            create :mappings => {
                     :bar => {
                       :properties => {
                         :name =>     { :type => 'string' },
                         :location => { :type => 'geo_point', :lat_lon => true }
                       }
                     }
                   }

            store :type => 'bar',
                  :name => 'one',
                  :location => {:lat => 53.54412, :lon => 9.94021}
            store :type => 'bar',
                  :name => 'two',
                  :location => {:lat => 53.54421, :lon => 9.94673}
            store :type => 'bar',
                  :name => 'three',
                  :location => {:lat => 53.55099, :lon => 10.02527}
            refresh
          end
        end

        teardown { @index.delete }

        should "return aggregated values for all results" do
          s = Tire.search('bars-test') do
            query { all }
            facet 'geo' do
              geo_distance :location,
                           {:lat => 53.54507, :lon => 9.95309},
                           [{:to => 1}, {:from => 1, :to => 10}, {:from => 50}],
                           unit: 'km'
            end
          end

          facets = s.results.facets['geo']['ranges']
          assert_equal 3, facets.size, facets.inspect
          assert_equal 2, facets.entries[0]['total_count'], facets.inspect
          assert_equal 1, facets.entries[1]['total_count'], facets.inspect
          assert_equal 0, facets.entries[2]['total_count'], facets.inspect
        end
      end

      context "statistical" do

        should "return computed statistical data on a numeric field" do
          s = Tire.search('articles-test') do
            query { all }
            facet 'word_stats' do
              statistical :words
            end
          end

          facets = s.results.facets["word_stats"]
          assert_equal 5,      facets["count"], facets.inspect
          assert_equal 1125.0, facets["total"], facets.inspect
          assert_equal 125.0,  facets["min"], facets.inspect
          assert_equal 375.0,  facets["max"], facets.inspect
          assert_equal 225.0,  facets["mean"], facets.inspect
        end

        should "return computed statistical data by given script" do
          s = Tire.search('articles-test') do
            query { all }
            facet 'word_stats' do
              statistical :statistical => { :script => "doc['words'].value * factor",
                                            :params => { :factor => 2 } }
            end
          end

          facets = s.results.facets["word_stats"]
          assert_equal 2250.0, facets["total"], facets.inspect
        end

      end

      context "terms_stats" do

        should "return computed stats computed on a field, per term value driven by another field" do
          s = Tire.search('articles-test') do
            query { all }
            facet 'words_per_tag_stats' do
              terms_stats :tags, :words
            end
          end
          facets = s.results.facets['words_per_tag_stats']['terms']

          assert_equal({"term" => "ruby", "count" => 2, "total_count"=> 2, "min"=> 125.0, "max"=> 250.0, "total"=> 375.0, "mean"=> 187.5}, facets[0], facets.inspect)
          assert_equal({"term" => "java", "count" => 2, "total_count"=> 2, "min"=> 125.0, "max"=> 375.0, "total"=> 500.0, "mean"=> 250.0}, facets[1], facets.inspect)
          assert_equal({"term" => "python", "count" => 1, "total_count"=> 1, "min"=> 250.0, "max"=> 250.0, "total"=> 250.0, "mean"=> 250.0}, facets[2], facets.inspect)
        end

      end

      context "query facets" do

        should "return aggregated values for a string query" do
          s = Tire.search('articles-test') do
            facet 'tees' do
              query { string 'T*' }
            end
          end

          count = s.results.facets['tees']['count']
          assert_equal 2, count, s.results.facets['tees'].inspect
        end

        should "return aggregated values for _exists_ string query" do
          s = Tire.search('articles-test') do
            facet 'drafts' do
              query { string '_exists_:draft' }
            end
          end

          count = s.results.facets['drafts']['count']
          assert_equal 1, count, s.results.facets['drafts'].inspect
        end

        should "return aggregated values for a terms query" do
          s = Tire.search('articles-test') do
            facet 'friends' do
              query { terms :tags, ['ruby', 'python'] }
            end
          end

          count = s.results.facets['friends']['count']
          assert_equal 2, count, s.results.facets['friends'].inspect

          s = Tire.search('articles-test') do
            facet 'friends' do
              query { terms :tags, ['ruby', 'python'], :minimum_match => 2 }
            end
          end

          count = s.results.facets['friends']['count']
          assert_equal 1, count, s.results.facets['friends'].inspect
        end

      end

      context "filter" do

        should "return a filter facet" do
          s = Tire.search('articles-test', :search_type => 'count') do
            facet 'filtered' do
              filter :range, :words => { :from => 100, :to => 200 }
            end
          end

          facets = s.results.facets["filtered"]
          assert_equal 2, facets["count"], facets.inspect
        end

      end

    end
  end
end
