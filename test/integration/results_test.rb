require 'test_helper'

module Tire

  class ResultsIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Query results" do

      should "allow easy access to returned documents" do
        q = 'title:one'
        s = Tire.search('articles-test') { query { string q } }

        assert_equal 'One',  s.results.first.title
        assert_equal 'ruby', s.results.first.tags[0]
      end

      should "allow easy access to returned documents with limited fields" do
        q = 'title:one'
        s = Tire.search('articles-test') do
          query { string q }
          fields :title
        end

        assert_equal 'One', s.results.first.title
        assert_nil s.results.first.tags
      end

      should "allow to retrieve multiple fields" do
        q = 'title:one'
        s = Tire.search('articles-test') do
          query { string q }
          fields 'title', 'tags'
        end

        assert_equal 'One',  s.results.first.title
        assert_equal 'ruby', s.results.first.tags[0]
        assert_nil s.results.first.published_on
      end

      should "return script fields" do
        s = Tire.search('articles-test') do
          query { string 'title:one' }
          fields :title
          script_field :words_double, :script => "doc.words.value * 2"
        end

        assert_equal 'One', s.results.first.title
        assert_equal 250,   s.results.first.words_double
      end

      should "return specific fields, script fields and _source fields" do
        # Tire.configure { logger STDERR, level: 'debug' }

        s = Tire.search('articles-test') do
          query { string 'title:one' }
          fields :title, :_source
          script_field :words_double, :script => "doc.words.value * 2"
        end

        assert_equal 'One', s.results.first.title
        assert_equal 250,   s.results.first.words_double
      end

      should "iterate results with hits" do
        s = Tire.search('articles-test') { query { string 'title:one' } }

        s.results.each_with_hit do |result, hit|
          assert_instance_of Tire::Results::Item, result
          assert_instance_of Hash, hit

          assert_equal 'One', result.title
          assert_equal 'One', hit['_source']['title']
          assert_not_nil hit['_score']
        end
      end

      should "be serialized to JSON" do
        s = Tire.search('articles-test') { query { string 'title:one' } }

        assert_not_nil s.results.as_json(only: 'title').first['title']
        assert_nil     s.results.as_json(only: 'title').first['published_on']
      end

    end
  end

end
