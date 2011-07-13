require 'test_helper'

class ModelWithIndexCallbacks
  extend ActiveModel::Naming
  extend ActiveModel::Callbacks

  include Tire::Model::Search
  include Tire::Model::Callbacks

  def destroyed?;         false;        end
  def serializable_hash;  {:one => 1};  end
end

module Tire
  module Model

    class SearchTest < Test::Unit::TestCase

      context "Model::Search" do

        setup do
          @stub = stub('search') { stubs(:query).returns(self); stubs(:perform).returns(self); stubs(:results).returns([]) }
          Tire::Index.any_instance.stubs(:exists?).returns(false)
        end

        teardown do
          ActiveModelArticleWithCustomIndexName.index_name 'custom-index-name'
        end

        should "have the search method" do
          assert_respond_to Model::Search, :search
          assert_respond_to ActiveModelArticle, :search
        end

        should "have the `update_elastic_search_index` callback methods defined" do
          assert_respond_to ::ModelWithIndexCallbacks, :before_update_elastic_search_index
          assert_respond_to ::ModelWithIndexCallbacks, :after_update_elastic_search_index
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

        should "limit searching in index for documents matching the model 'document_type'" do
          Tire::Search::Search.
            expects(:new).
            with(ActiveModelArticle.index_name, { :type => ActiveModelArticle.document_type }).
            returns(@stub).
            twice

          ActiveModelArticle.search 'foo'
          ActiveModelArticle.search { query { string 'foo' } }
        end

        should "search in custom name" do
          first  = 'custom-index-name'
          second = 'another-custom-index-name'
          expected_options = { :type => ActiveModelArticleWithCustomIndexName.document_type }

          Tire::Search::Search.expects(:new).with(first, expected_options).returns(@stub).twice
          ActiveModelArticleWithCustomIndexName.index_name first
          ActiveModelArticleWithCustomIndexName.search 'foo'
          ActiveModelArticleWithCustomIndexName.search { query { string 'foo' } }

          Tire::Search::Search.expects(:new).with(second, expected_options).returns(@stub).twice
          ActiveModelArticleWithCustomIndexName.index_name second
          ActiveModelArticleWithCustomIndexName.search 'foo'
          ActiveModelArticleWithCustomIndexName.search { query { string 'foo' } }

          Tire::Search::Search.expects(:new).with(first, expected_options).returns(@stub).twice
          ActiveModelArticleWithCustomIndexName.index_name first
          ActiveModelArticleWithCustomIndexName.search 'foo'
          ActiveModelArticleWithCustomIndexName.search { query { string 'foo' } }
        end

        should "allow to refresh index" do
          Index.any_instance.expects(:refresh)

          ActiveModelArticle.elasticsearch_index.refresh
        end

        should "wrap results in instances of the wrapper class" do
          response = { 'hits' => { 'hits' => [{'_id' => 1, '_score' => 0.8, '_source' => { 'title' => 'Article' }}] } }
          Configuration.client.expects(:get).returns(mock_response(response.to_json))

          collection = ActiveModelArticle.search 'foo'
          assert_instance_of Results::Collection, collection

          document = collection.first

          assert_instance_of Results::Item, document
          assert_not_nil     document._score
          assert_equal 1,    document.id
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
            Tire::Search::Sort.any_instance.expects(:by).with('title', nil)

            ActiveModelArticle.search @q, :order => 'title'
          end

          should "allow to pass :sort option as :order option" do
            Tire::Search::Sort.any_instance.expects(:by).with('title', nil)

            ActiveModelArticle.search @q, :sort => 'title'
          end

          should "allow to specify sort direction" do
            Tire::Search::Sort.any_instance.expects(:by).with('title', 'DESC')

            ActiveModelArticle.search @q, :order => 'title DESC'
          end

          should "allow to specify more fields to sort on" do
            Tire::Search::Sort.any_instance.expects(:by).with('title', 'DESC')
            Tire::Search::Sort.any_instance.expects(:by).with('author.name', nil)

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
          Tire::Index.any_instance.expects(:store).returns({})

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
              extend ActiveModel::Callbacks

              include Tire::Model::Search
              include Tire::Model::Callbacks

              mapping do
                indexes :title, :type => 'string', :analyzer => 'snowball', :boost => 10
              end

            end

            assert_equal 'snowball', ModelWithCustomMapping.mapping[:title][:analyzer]
          end

          should "define mapping for nested properties with a block" do
            expected_mapping = {
              :mappings => { :model_with_nested_mapping => {
                :properties => {
                  :title =>  { :type => 'string' },
                  :author => {
                    :type => 'object',
                    :properties => {
                      :first_name => { :type => 'string' },
                      :last_name  => { :type => 'string', :boost => 100 }
                    }
                  }
                }
              }
            }}

            Tire::Index.any_instance.expects(:create).with(expected_mapping)

            class ::ModelWithNestedMapping
              extend ActiveModel::Naming
              extend ActiveModel::Callbacks

              include Tire::Model::Search
              include Tire::Model::Callbacks

              mapping do
                indexes :title, :type => 'string'
                indexes :author do
                  indexes :first_name, :type => 'string'
                  indexes :last_name,  :type => 'string', :boost => 100
                end
              end

            end

            assert_not_nil ModelWithNestedMapping.mapping[:author][:properties][:last_name]
            assert_equal   100, ModelWithNestedMapping.mapping[:author][:properties][:last_name][:boost]
          end

        end

        context "with index update callbacks" do
          setup do
            class ::ModelWithIndexCallbacks
              _update_elastic_search_index_callbacks.clear
              def notify; end
            end

            response = { 'ok'  => true,
                         '_id' => 1,
                         'matches' => ['foo'] }
            Configuration.client.expects(:post).returns(mock_response(response.to_json))
          end

          should "run the callback defined as block" do
            class ::ModelWithIndexCallbacks
              after_update_elastic_search_index { self.go! }
            end

            @model = ::ModelWithIndexCallbacks.new
            @model.expects(:go!)

            @model.update_elastic_search_index
          end

          should "run the callback defined as symbol" do
            class ::ModelWithIndexCallbacks
              after_update_elastic_search_index :notify

              def notify; self.go!; end
            end

            @model = ::ModelWithIndexCallbacks.new
            @model.expects(:go!)

            @model.update_elastic_search_index
          end

          should "set the 'matches' property from percolated response" do
            @model = ::ModelWithIndexCallbacks.new
            @model.update_elastic_search_index

            assert_equal ['foo'], @model.matches
          end

        end

        context "serialization" do
          setup { Tire::Index.any_instance.stubs(:create).returns(true) }

          should "have to_hash" do
            assert_equal( {'title' => 'Test'}, ActiveModelArticle.new( 'title' => 'Test' ).to_hash )
          end

          should "not redefine to_hash if already defined" do
            class ::ActiveModelArticleWithToHash < ActiveModelArticle
              def to_hash; { :foo => 'bar' }; end
            end
            assert_equal 'bar', ::ActiveModelArticleWithToHash.new(:title => 'Test').to_hash[:foo]

            class ::ActiveModelArticleWithToHashFromSuperclass < Hash
              include Tire::Model::Search
              include Tire::Model::Callbacks
            end
            assert_equal( {}, ::ActiveModelArticleWithToHashFromSuperclass.new(:title => 'Test').to_hash)
          end

          should "serialize itself into JSON without 'root'" do
            @model = ActiveModelArticle.new 'title' => 'Test'
            assert_equal({'title' => 'Test'}.to_json, @model.to_indexed_json)
          end

          should "serialize itself with serializable_hash when no mapping is set" do

            class ::ModelWithoutMapping
              extend  ActiveModel::Naming
              extend ActiveModel::Callbacks
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
              extend ActiveModel::Callbacks
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

        context "with percolation" do
          setup do
            class ::ActiveModelArticleWithCallbacks; percolate!(false); end
            @article = ::ActiveModelArticleWithCallbacks.new :title => 'Test'
          end

          should "return matching queries on percolate" do
            Tire::Index.any_instance.expects(:percolate).returns(["alert"])

            assert_equal ['alert'], @article.percolate
          end

          should "pass the arguments to percolate" do
            filter   = lambda { string 'tag:alerts' }

            Tire::Index.any_instance.expects(:percolate).with do |type,doc,query|
              # p [type,doc,query]
              type  == 'active_model_article_with_callbacks' &&
              doc   == @article &&
              query == filter
            end.returns(["alert"])

            assert_equal ['alert'], @article.percolate(&filter)
          end

          should "mark the instance for percolation on index update" do
            @article.percolate = true

            Tire::Index.any_instance.expects(:store).with do |doc,options|
              # p [doc,options]
              options[:percolate] == true
            end.returns(MultiJson.decode('{"ok":true,"_id":"test","matches":["alerts"]}'))

            @article.update_elastic_search_index
          end

          should "not percolate document on index update when not set for percolation" do
            Tire::Index.any_instance.expects(:store).with do |doc,options|
              # p [doc,options]
              options[:percolate] == nil
            end.returns(MultiJson.decode('{"ok":true,"_id":"test"}'))

            @article.update_elastic_search_index
          end

          should "set the default percolator pattern" do
            class ::ActiveModelArticleWithPercolation < ::ActiveModelArticleWithCallbacks
              percolate!
            end

            assert_equal true, ::ActiveModelArticleWithCallbacks.percolator
          end

          should "set the percolator pattern" do
            class ::ActiveModelArticleWithPercolation < ::ActiveModelArticleWithCallbacks
              percolate! 'tags:alert'
            end

            assert_equal 'tags:alert', ::ActiveModelArticleWithCallbacks.percolator
          end

          should "mark the class for percolation on index update" do
            class ::ActiveModelArticleWithPercolation < ::ActiveModelArticleWithCallbacks
              percolate!
            end

            Tire::Index.any_instance.expects(:store).with do |doc,options|
              # p [doc,options]
              options[:percolate] == true
            end.returns(MultiJson.decode('{"ok":true,"_id":"test","matches":["alerts"]}'))

            percolated = ActiveModelArticleWithPercolation.new :title => 'Percolate me!'
            percolated.update_elastic_search_index
          end

          should "execute the 'on_percolate' callback" do
            $test__matches = nil
            class ::ActiveModelArticleWithPercolation < ::ActiveModelArticleWithCallbacks
              on_percolate { $test__matches = matches }
            end
            percolated = ActiveModelArticleWithPercolation.new :title => 'Percolate me!'

            Tire::Index.any_instance.expects(:store).
                                     with do |doc,options|
                                       doc == percolated &&
                                       options[:percolate] == true
                                     end.
                                     returns(MultiJson.decode('{"ok":true,"_id":"test","matches":["alerts"]}'))

            percolated.update_elastic_search_index

            assert_equal ['alerts'], $test__matches
          end

          should "execute the 'on_percolate' callback for specific pattern" do
            $test__matches = nil
            class ::ActiveModelArticleWithPercolation < ::ActiveModelArticleWithCallbacks
              on_percolate('tags:alert') { $test__matches = self.matches }
            end
            percolated = ActiveModelArticleWithPercolation.new :title => 'Percolate me!'

            Tire::Index.any_instance.expects(:store).
                                     with do |doc,options|
                                       doc == percolated &&
                                       options[:percolate] == 'tags:alert'
                                     end.
                                     returns(MultiJson.decode('{"ok":true,"_id":"test","matches":["alerts"]}'))

            percolated.update_elastic_search_index

            assert_equal ['alerts'], $test__matches
          end

        end

      end

    end

  end
end
