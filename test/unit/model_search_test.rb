require 'test_helper'

module Tire
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

        should_eventually "contain all Tire class/instance methods in a proxy object" do
        end

        should_eventually "include Tire class methods in class top-level namespace when they do not exist" do
        end

        should_eventually "include Tire instance methods in instance top-level namespace when they do not exist" do
        end

        should_eventually "NOT overload existing top-level class methods" do
        end

        should_eventually "NOT overload existing top-level instance methods" do
        end

        should "search in index named after class name by default" do
          i = 'active_model_articles'
          Tire::Search::Search.expects(:new).with(i, {}).returns(@stub)

          ActiveModelArticle.search 'foo'
        end

        should_eventually "search only in document types for this class by default" do
        end

        should "search in custom name" do
          first  = 'custom-index-name'
          second = 'another-custom-index-name'

          Tire::Search::Search.expects(:new).with(first, {}).returns(@stub)
          ActiveModelArticleWithCustomIndexName.index_name 'custom-index-name'
          ActiveModelArticleWithCustomIndexName.search 'foo'

          Tire::Search::Search.expects(:new).with(second, {}).returns(@stub)
          ActiveModelArticleWithCustomIndexName.index_name 'another-custom-index-name'
          ActiveModelArticleWithCustomIndexName.search 'foo'

          Tire::Search::Search.expects(:new).with(first, {}).returns(@stub)
          ActiveModelArticleWithCustomIndexName.index_name 'custom-index-name'
          ActiveModelArticleWithCustomIndexName.search 'foo'
        end

        should "allow to refresh index" do
          Index.any_instance.expects(:refresh)

          ActiveModelArticle.elasticsearch_index.refresh
        end

        should "wrap results in proper class with ID and score and not change the original wrapper" do
          response = { 'hits' => { 'hits' => [{'_id' => 1, '_score' => 0.8, '_source' => { 'title' => 'Article' }}] } }
          Configuration.client.expects(:post).returns(mock_response(response.to_json))

          collection = ActiveModelArticle.search 'foo'
          assert_instance_of Results::Collection, collection

          assert_equal Results::Item, Tire::Configuration.wrapper

          document = collection.first

          assert_instance_of ActiveModelArticle, document
          assert_not_nil document.score
          assert_equal 1, document.id
          assert_equal 'Article', document.title
        end

        context "searching with a block" do

          should "pass on whatever block it received" do
            Tire::Search::Search.any_instance.expects(:perform).returns(@stub)
            Tire::Search::Query.any_instance.expects(:string).with('foo').returns(@stub)

            ActiveModelArticle.search { query { string 'foo' } }
          end

          should "allow to pass block with argument to query, allowing to use local variables from outer scope" do
            Tire::Search::Query.any_instance.expects(:instance_eval).never
            Tire::Search::Search.any_instance.expects(:perform).returns(@stub)
            Tire::Search::Query.any_instance.expects(:string).with('foo').returns(@stub)

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

            Tire::Search::Query.any_instance.expects(:string).with( @q ).returns(@stub)
            Tire::Search::Search.any_instance.expects(:perform).returns(@stub)
          end

          should "search for query string" do
            ActiveModelArticle.search @q
          end

          should "allow to pass :order option" do
            Tire::Search::Sort.any_instance.expects(:title)

            ActiveModelArticle.search @q, :order => 'title'
          end

          should "allow to pass :sort option as :order option" do
            Tire::Search::Sort.any_instance.expects(:title)

            ActiveModelArticle.search @q, :sort => 'title'
          end

          should "allow to specify sort direction" do
            Tire::Search::Sort.any_instance.expects(:title).with('DESC')

            ActiveModelArticle.search @q, :order => 'title DESC'
          end

          should "allow to specify more fields to sort on" do
            Tire::Search::Sort.any_instance.expects(:title).with('DESC')
            Tire::Search::Sort.any_instance.expects(:field).with('author.name', nil)

            ActiveModelArticle.search @q, :order => ['title DESC', 'author.name']
          end

          should "allow to specify number of results per page" do
            Tire::Search::Search.any_instance.expects(:size).with(20)

            ActiveModelArticle.search @q, :per_page => 20
          end

          should "allow to specify first page in paginated results" do
            Tire::Search::Search.any_instance.expects(:size).with(10)
            Tire::Search::Search.any_instance.expects(:from).with(0)

            ActiveModelArticle.search @q, :per_page => 10, :page => 1
          end

          should "allow to specify page further in paginated results" do
            Tire::Search::Search.any_instance.expects(:size).with(10)
            Tire::Search::Search.any_instance.expects(:from).with(20)

            ActiveModelArticle.search @q, :per_page => 10, :page => 3
          end

        end

        should "not set callback when hooks are missing" do
          @model = ActiveModelArticle.new
          @model.expects(:update_elastic_search_index).never

          @model.save
        end

        should_eventually "not define destroyed? if class already implements it" do
          load File.expand_path('../../models/active_model_article_with_callbacks.rb', __FILE__)

          # TODO: Find a way how to break the old implementation:
          #       if base.respond_to?(:before_destroy) && !base.respond_to?(:destroyed?)
          ActiveModelArticleWithCallbacks.expects(:class_eval).never
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
          Tire::Index.any_instance.expects(:store)

          @model.save
        end

        should "remove the record from index on :update_elastic_search_index when destroyed" do
          @model = ActiveModelArticleWithCallbacks.new
          i = mock('index') { expects(:remove) }
          Tire::Index.expects(:new).with('active_model_article_with_callbacks').returns(i)

          @model.destroy
        end

        context "with custom mapping" do

          should "create the index with mapping" do
            expected_mapping = {
              :mappings => { :model_with_custom_mapping => {
                :properties => { :title => { :type => 'string', :analyzer => 'snowball', :boost => 10 } }
              }}
            }

            Tire::Index.any_instance.expects(:create).with(expected_mapping)

            class ::ModelWithCustomMapping
              extend ActiveModel::Naming

              include Tire::Model::Search
              include Tire::Model::Callbacks

              mapping do
                indexes :title, :type => 'string', :analyzer => 'snowball', :boost => 10
              end

            end

            assert_equal 'snowball', ModelWithCustomMapping.mapping[:title][:analyzer]
          end

        end

        context "serialization" do
          setup { Tire::Index.any_instance.stubs(:create).returns(true) }

          should "serialize itself into JSON without 'root'" do
            @model = ActiveModelArticle.new 'title' => 'Test'
            assert_equal({'title' => 'Test'}.to_json, @model.to_indexed_json)
          end

          should "serialize itself with serializable_hash when no mapping is set" do

            class ::ModelWithoutMapping
              extend  ActiveModel::Naming
              include ActiveModel::Serialization
              include Tire::Model::Search
              include Tire::Model::Callbacks

              # Do NOT configure any mapping

              attr_reader :attributes

              def initialize(attributes = {}); @attributes = attributes; end

              def method_missing(name, *args, &block)
                attributes[name.to_sym] || attributes[name.to_s] || super
              end
            end

            model = ::ModelWithoutMapping.new :one => 1, :two => 2
            assert_equal( {:one => 1, :two => 2}, model.serializable_hash )

            # Bot properties are returned
            assert_equal( {:one => 1, :two => 2}.to_json, model.to_indexed_json )
          end

          should "serialize only mapped properties when mapping is set" do

            class ::ModelWithMapping
              extend  ActiveModel::Naming
              include ActiveModel::Serialization
              include Tire::Model::Search
              include Tire::Model::Callbacks

              mapping do
                # ONLY index the 'one' attribute
                indexes :one, :type => 'string', :analyzer => 'keyword'
              end

              attr_reader :attributes

              def initialize(attributes = {}); @attributes = attributes; end

              def method_missing(name, *args, &block)
                attributes[name.to_sym] || attributes[name.to_s] || super
              end
            end

            model = ::ModelWithMapping.new :one => 1, :two => 2
            assert_equal( {:one => 1, :two => 2}, model.serializable_hash )

            # Only the mapped property is returned
            assert_equal( {:one => 1}.to_json, model.to_indexed_json )

          end

        end

      end

    end

  end
end
