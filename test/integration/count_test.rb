require 'test_helper'

module Tire

  class CountIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Count with search type" do

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

    context "Count with the count method" do
      setup    { Tire.index('articles-test-count') { delete; create and store(title: 'Test') and refresh } }
      teardown { Tire.index('articles-test-count') { delete } }

      should "return number of documents in the index" do
        assert_equal 5, Tire.count('articles-test')
      end

      should "return number of documents in the index for specific query" do
        # Tire.configure { logger STDERR, level: 'debug' }
        count = Tire.count('articles-test') do
          term :tags, 'ruby'
        end
        assert_equal 2, count
      end

      should "return number of documents in multiple indices" do
        assert_equal 6, Tire.count(['articles-test', 'articles-test-count'])
      end

      should "allow access to the JSON and response" do
        c = Tire::Search::Count.new('articles-test')
        c.perform
        assert_equal 5, c.value
        assert_equal 0, c.json['_shards']['failed']
        assert c.response.success?, "Response should be successful: #{c.response.inspect}"
      end

    end

  end
end
