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


          should "search for query string" do
            q = 'foo AND bar'

            Slingshot::Search::Query.any_instance.expects(:string).with( q )
            Slingshot::Search::Search.any_instance.expects(:perform).returns(true)

            ActiveModelArticle.search q
          end

        end

      end

    end

  end
end
