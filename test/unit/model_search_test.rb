require 'test_helper'

module Slingshot
  module Model

    class SearchTest < Test::Unit::TestCase

      context "Model::Search" do

        should "have the search method" do
          assert_respond_to Model::Search, :search
          assert_respond_to ActiveModelArticle, :search
        end

        should "search in specific index" do
          i = 'active_model_articles'
          q = 'foo'
          s = stub('search') { stubs(:query).returns(self); stubs(:perform).returns(self) }
          Slingshot::Search::Search.expects(:new).with(i, {}).returns(s)

          ActiveModelArticle.search q
        end

        context "searching with a block" do

          should "pass on whatever block it received" do
            Slingshot::Search::Search.any_instance.expects(:perform)
            Slingshot::Search::Query.any_instance.expects(:string).with('foo')

            ActiveModelArticle.search { query { string 'foo' } }
          end

        end

        context "searching with query string" do

          setup do
            @q = 'foo AND bar'

            Slingshot::Search::Query.any_instance.expects(:string).with( @q )
            Slingshot::Search::Search.any_instance.expects(:perform).returns(true)
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

        end

      end

    end

  end
end
