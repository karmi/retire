require 'test_helper'

module Slingshot

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

    context "ActiveModel" do

      setup    do
        Slingshot.index('supermodel_articles').delete
        load File.expand_path('../../models/supermodel_article.rb', __FILE__)
      end
      teardown { Slingshot.index('supermodel_articles').delete }

      should "configure mapping" do
        assert_equal 'czech', SupermodelArticle.mapping[:title][:analyzer]
        assert_equal 15,      SupermodelArticle.mapping[:title][:boost]

        assert_equal 'czech', SupermodelArticle.index.mapping['supermodel_article']['properties']['title']['analyzer']
      end

      should "save document into index on save and find it with score" do
        a = SupermodelArticle.new :title => 'Test'
        a.save
        id = a.id

        a.index.refresh
        sleep(1.5)

        results = SupermodelArticle.search 'test'

        assert_equal 1, results.count
        assert_instance_of SupermodelArticle, results.first
        assert_equal       'Test', results.first.title
        assert_not_nil     results.first.score
        assert_equal       id, results.first.id
      end

      should "remove document from index on destroy" do
        a = SupermodelArticle.new :title => 'Test'
        a.save
        a.destroy

        a.index.refresh
        sleep(1.25)

        results = SupermodelArticle.search 'test'
        
        assert_equal 0, results.count
      end

      should "retrieve sorted documents by IDs returned from search" do
        SupermodelArticle.create! :title => 'foo'
        SupermodelArticle.create! :title => 'bar'

        SupermodelArticle.index.refresh
        results = SupermodelArticle.search 'foo OR bar^100'

        assert_equal 2, results.count

        assert_equal 'bar', results.first.title
      end

    end

  end

end
