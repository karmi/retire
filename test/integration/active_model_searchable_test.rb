require 'test_helper'
require File.expand_path('../../models/supermodel_article', __FILE__)

module Tire

  class ActiveModelSearchableIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    def setup
      super
      Redis::Persistence.config.redis = Redis.new db: ENV['REDIS_PERSISTENCE_TEST_DATABASE'] || 14
      Redis::Persistence.config.redis.flushdb
      @model = SupermodelArticle.new :title => 'Test'
    end

    def teardown
      super
      SupermodelArticle.all.each { |a| a.destroy }
    end

    context "ActiveModel integration" do

      setup    do
        Tire.index('supermodel_articles').delete
        load File.expand_path('../../models/supermodel_article.rb', __FILE__)
      end
      teardown { Tire.index('supermodel_articles').delete }

      should "configure mapping" do
        assert_equal 'czech', SupermodelArticle.mapping[:title][:analyzer]
        assert_equal 15,      SupermodelArticle.mapping[:title][:boost]

        assert_equal 'czech', SupermodelArticle.index.mapping['supermodel_article']['properties']['title']['analyzer']
      end

      should "save document into index on save and find it with score" do
        a = SupermodelArticle.new :title => 'Test'
        a.save
        id = a.id

        # Store document of another type in the index
        Index.new 'supermodel_articles' do
          store :type => 'other-thing', :title => 'Title for other thing'
        end

        a.index.refresh

        # The index should contain 2 documents
        assert_equal 2, Tire.search('supermodel_articles') { query { all } }.results.size

        results = SupermodelArticle.search 'test'

        # The model should find only 1 document
        assert_equal 1, results.count

        assert_instance_of Results::Item, results.first
        assert_equal       'Test', results.first.title
        assert_not_nil     results.first._score
        assert_equal       id.to_s, results.first.id.to_s
      end

      should "remove document from index on destroy" do
        a = SupermodelArticle.new :title => 'Test'
        a.save
        assert_equal 1, SupermodelArticle.all.size

        a.destroy
        assert_equal 0, SupermodelArticle.all.size

        a.index.refresh
        results = SupermodelArticle.search 'test'

        assert_equal 0, results.count
      end

      should "retrieve sorted documents by IDs returned from search" do
        SupermodelArticle.create :title => 'foo'
        SupermodelArticle.create :id => 'abc123', :title => 'bar'

        SupermodelArticle.index.refresh
        results = SupermodelArticle.search 'foo OR bar^100'

        assert_equal 2, results.count

        assert_equal 'bar',    results.first.title
        assert_equal 'abc123', results.first.id
      end

      should "return facets" do
        a = SupermodelArticle.new :title => 'Test'
        a.save
        a.index.refresh

        s = SupermodelArticle.search do
          query { match :title, 'test' }
          facet 'title' do
            terms :title
          end
        end

        assert_equal 1, s.facets['title']['terms'][0]['count']
      end

      context "within Rails" do

        setup do
          module ::Rails; end
          @article = SupermodelArticle.new :title => 'Test'
          @article.save
          @article.index.refresh
        end

        should "fake the underlying model with _source" do
          results = SupermodelArticle.search 'test'

          assert_instance_of Results::Item, results.first
          assert_instance_of SupermodelArticle, results.first.load
          assert_equal 'Test', results.first.load.title
        end

        should "load the record from database" do
          results = SupermodelArticle.search 'test', load: true

          assert_instance_of SupermodelArticle, results.first
          assert_equal 'Test', results.first.title
        end

      end

    end

  end

end
