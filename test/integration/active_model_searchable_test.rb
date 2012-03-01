require 'test_helper'

module Tire

  class ActiveModelSearchableIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    def setup
      super
      SupermodelArticle.delete_all
      @model = SupermodelArticle.new :title => 'Test'
    end

    def teardown
      super
      SupermodelArticle.delete_all
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
        assert_equal       id, results.first.id
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
        SupermodelArticle.create! :title => 'foo'
        SupermodelArticle.create! :id => 'abc123', :title => 'bar'

        SupermodelArticle.index.refresh
        results = SupermodelArticle.search 'foo OR bar^100'

        assert_equal 2, results.count

        assert_equal 'bar',    results.first.title
        assert_equal 'abc123', results.first.id
      end

      context "with default filter" do
        setup do
          SupermodelArticleWithDefaultFilter.index.delete
          SupermodelArticleWithDefaultFilter.create! :title => 'foo', :status => 'active'
          SupermodelArticleWithDefaultFilter.create! :title => 'foo', :status => 'inactive'
          SupermodelArticleWithDefaultFilter.index.refresh
        end

        should "search with default filter" do
          results = SupermodelArticleWithDefaultFilter.search 'foo'

          assert_equal 1, results.count
          assert_equal false, results.to_a.collect(&:status).include?('inactive')
        end

        should "not search with default filter when unscoped options is true" do
          results = SupermodelArticleWithDefaultFilter.search 'foo', :unscoped => true

          assert_equal 2, results.count
          assert_equal true, results.to_a.collect(&:status).include?('inactive')
        end
      end

      context "within Rails" do

        setup do
          module ::Rails; end
        end

        should "load the underlying model" do
          a = SupermodelArticle.new :title => 'Test'
          a.save
          a.index.refresh

          results = SupermodelArticle.search 'test'

          assert_instance_of Results::Item, results.first
          assert_instance_of SupermodelArticle, results.first.load

          assert_equal 'Test', results.first.load.title
        end

      end

    end

  end

end
