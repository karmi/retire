require 'test_helper'

module Slingshot
  module Model

    class SearchTest < Test::Unit::TestCase

      context "Model::Search" do

        setup do
          @stub = stub('search') { stubs(:query).returns(self); stubs(:perform).returns(self); stubs(:results).returns([]) }
        end

        teardown do
          ActiveModelArticleWithCustomIndexName.index_name 'custom-index-name'
        end

        should "have the search method" do
          assert_respond_to Model::Search, :search
          assert_respond_to ActiveModelArticle, :search
        end

        should "search in index named after class name by default" do
          i = 'active_model_articles'
          Slingshot::Search::Search.expects(:new).with(i, {}).returns(@stub)

          ActiveModelArticle.search 'foo'
        end

        should "search in custom name" do
          first  = 'custom-index-name'
          second = 'another-custom-index-name'

          Slingshot::Search::Search.expects(:new).with(first, {}).returns(@stub)
          ActiveModelArticleWithCustomIndexName.index_name 'custom-index-name'
          ActiveModelArticleWithCustomIndexName.search 'foo'

          Slingshot::Search::Search.expects(:new).with(second, {}).returns(@stub)
          ActiveModelArticleWithCustomIndexName.index_name 'another-custom-index-name'
          ActiveModelArticleWithCustomIndexName.search 'foo'

          Slingshot::Search::Search.expects(:new).with(first, {}).returns(@stub)
          ActiveModelArticleWithCustomIndexName.index_name 'custom-index-name'
          ActiveModelArticleWithCustomIndexName.search 'foo'
        end

        should "allow to refresh index" do
          Index.any_instance.expects(:refresh)

          ActiveModelArticle.index.refresh
        end

        should "wrap results in proper class with ID and score and not change the original wrapper" do
          response = { 'hits' => { 'hits' => [{'_id' => 1, '_score' => 0.8, '_source' => { 'title' => 'Article' }}] } }
          Configuration.client.expects(:post).returns(response.to_json)

          collection = ActiveModelArticle.search 'foo'
          assert_instance_of Results::Collection, collection

          assert_equal Results::Item, Slingshot::Configuration.wrapper

          document = collection.first

          assert_instance_of ActiveModelArticle, document
          assert_not_nil document.score
          assert_equal 1, document.id
          assert_equal 'Article', document.title
        end

        context "searching with a block" do

          should "pass on whatever block it received" do
            Slingshot::Search::Search.any_instance.expects(:perform).returns(@stub)
            Slingshot::Search::Query.any_instance.expects(:string).with('foo').returns(@stub)

            ActiveModelArticle.search { query { string 'foo' } }
          end

          should "allow to pass block with argument to query, allowing to use local variables from outer scope" do
            Slingshot::Search::Query.any_instance.expects(:instance_eval).never
            Slingshot::Search::Search.any_instance.expects(:perform).returns(@stub)
            Slingshot::Search::Query.any_instance.expects(:string).with('foo').returns(@stub)

            my_query = 'foo'
            ActiveModelArticle.search do
              query do |query|
                query.string(my_query)
              end
            end
          end

        end

        context "searching with query string" do

          setup do
            @q = 'foo AND bar'

            Slingshot::Search::Query.any_instance.expects(:string).with( @q ).returns(@stub)
            Slingshot::Search::Search.any_instance.expects(:perform).returns(@stub)
          end

          should "search for query string" do
            ActiveModelArticle.search @q
          end

          should "allow to pass :order option" do
            Slingshot::Search::Sort.any_instance.expects(:title)

            ActiveModelArticle.search @q, :order => 'title'
          end

          should "allow to pass :sort option as :order option" do
            Slingshot::Search::Sort.any_instance.expects(:title)

            ActiveModelArticle.search @q, :sort => 'title'
          end

          should "allow to specify sort direction" do
            Slingshot::Search::Sort.any_instance.expects(:title).with('DESC')

            ActiveModelArticle.search @q, :order => 'title DESC'
          end

          should "allow to specify more fields to sort on" do
            Slingshot::Search::Sort.any_instance.expects(:title).with('DESC')
            Slingshot::Search::Sort.any_instance.expects(:field).with('author.name', nil)

            ActiveModelArticle.search @q, :order => ['title DESC', 'author.name']
          end

          should "allow to specify number of results per page" do
            Slingshot::Search::Search.any_instance.expects(:size).with(20)

            ActiveModelArticle.search @q, :per_page => 20
          end

          should "allow to specify first page in paginated results" do
            Slingshot::Search::Search.any_instance.expects(:size).with(10)
            Slingshot::Search::Search.any_instance.expects(:from).with(0)

            ActiveModelArticle.search @q, :per_page => 10, :page => 1
          end

          should "allow to specify page further in paginated results" do
            Slingshot::Search::Search.any_instance.expects(:size).with(10)
            Slingshot::Search::Search.any_instance.expects(:from).with(20)

            ActiveModelArticle.search @q, :per_page => 10, :page => 3
          end

        end

        should "not set callback when hooks are missing" do
          @model = ActiveModelArticle.new
          @model.expects(:update_elastic_search_index).never

          @model.save
        end

        should "fire :after_save callbacks" do
          @model = ActiveModelArticleWithCallbacks.new
          @model.expects(:update_elastic_search_index)

          @model.save
        end

        should "fire :after_destroy callbacks" do
          @model = ActiveModelArticleWithCallbacks.new
          @model.expects(:update_elastic_search_index)

          @model.destroy
        end

        should "store the record in index on :update_elastic_search_index when saved" do
          @model = ActiveModelArticleWithCallbacks.new
          Slingshot::Index.any_instance.expects(:store)

          @model.save
        end

        should "remove the record from index on :update_elastic_search_index when destroyed" do
          @model = ActiveModelArticleWithCallbacks.new
          i = mock('index') { expects(:remove) }
          Slingshot::Index.expects(:new).with('active_model_article_with_callbacks').returns(i)

          @model.destroy
        end

      end

      context "ActiveModel" do

        should "serialize itself into JSON without 'root'" do
          @model = ActiveModelArticle.new 'title' => 'Test'
          assert_equal({'title' => 'Test'}.to_json, @model.to_indexed_json)
        end
        
      end

    end

  end
end
