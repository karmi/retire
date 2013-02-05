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
          @stub = stub('search') { stubs(:query).returns(self); stubs(:perform).returns(self); stubs(:results).returns([]); stubs(:size).returns(true) }
          Tire::Index.any_instance.stubs(:exists?).returns(false)
        end

        teardown do
          ActiveModelArticleWithCustomIndexName.index_name 'custom-index-name'
        end

        should "have the search method" do
          assert_respond_to ActiveModelArticle, :search
        end

        should "have the callback methods for update index defined" do
          assert_respond_to ::ModelWithIndexCallbacks, :before_update_elasticsearch_index
          assert_respond_to ::ModelWithIndexCallbacks, :after_update_elasticsearch_index
        end

        should "limit searching in index for documents matching the model 'document_type'" do
          Tire::Search::Search.
            expects(:new).
            with('active_model_articles', { :type => 'active_model_article' }).
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

        should "search in custom type" do
          name = ActiveModelArticleWithCustomDocumentType.index_name
          Tire::Search::Search.expects(:new).with(name, { :type => 'my_custom_type' }).returns(@stub).twice

          ActiveModelArticleWithCustomDocumentType.search 'foo'
          ActiveModelArticleWithCustomDocumentType.search { query { string 'foo' } }
        end

        should "allow to pass custom document type" do
          Tire::Search::Search.
            expects(:new).
            with(ActiveModelArticle.index_name, { :type => 'custom_type' }).
            returns(@stub).
            twice

          ActiveModelArticle.search 'foo', :type => 'custom_type'
          ActiveModelArticle.search( :type => 'custom_type' ) { query { string 'foo' } }
        end

        should "allow to pass custom index name" do
          Tire::Search::Search.
            expects(:new).
            with('custom_index', { :type => ActiveModelArticle.document_type }).
            returns(@stub).
            twice

          ActiveModelArticle.search 'foo', :index => 'custom_index'
          ActiveModelArticle.search( :index => 'custom_index' ) do
            query { string 'foo' }
          end
        end

        should "allow to refresh index" do
          Index.any_instance.expects(:refresh)

          ActiveModelArticle.index.refresh
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

        should "not pass the search option as URL parameter" do
          Configuration.client.
            expects(:get).with do |url, payload|
              assert ! url.include?('sort')
            end.
            returns( mock_response({ 'hits' => { 'hits' => [] } }.to_json) )

          ActiveModelArticle.search(@q, :sort => 'title:DESC').results
        end

        context "searching with a block" do
          setup do
            Tire::Search::Search.any_instance.expects(:perform).returns(@stub)
          end

          should "pass on whatever block it received" do
            Tire::Search::Query.any_instance.expects(:string).with('foo').returns(@stub)

            ActiveModelArticle.search { query { string 'foo' } }
          end

          should "allow to pass block with argument to query, allowing to use local variables from outer scope" do
            Tire::Search::Query.any_instance.expects(:instance_eval).never
            Tire::Search::Query.any_instance.expects(:string).with('foo').returns(@stub)

            my_query = 'foo'
            ActiveModelArticle.search do
              query do |query|
                query.string(my_query)
              end
            end
          end

          should "allow to pass :page and :per_page options" do
            Tire::Search::Search.any_instance.expects(:size).with(10)
            Tire::Search::Search.any_instance.expects(:from).with(20)

            ActiveModelArticle.search :per_page => 10, :page => 3 do
              query { string 'foo' }
            end
          end

          should "allow to pass :version option" do
            Tire::Search::Search.any_instance.expects(:version).with(true)

            ActiveModelArticle.search :version => true do
              query { all }
            end
          end

        end

        context "searching with query string" do

          setup do
            @q = 'foo AND bar'

            Tire::Search::Query.any_instance.expects(:string).at_least_once.with(@q).returns(@stub)
            Tire::Search::Search.any_instance.expects(:perform).at_least_once.returns(@stub)
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

            ActiveModelArticle.search @q, :order => 'title:DESC'
          end

          should "allow to specify more fields to sort on" do
            Tire::Search::Sort.any_instance.expects(:by).with('title', 'DESC')
            Tire::Search::Sort.any_instance.expects(:by).with('author.name', nil)

            ActiveModelArticle.search @q, :order => ['title:DESC', 'author.name']
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

          should "allow to limit returned fields" do
            Tire::Search::Search.any_instance.expects(:fields).with(["id"])
            ActiveModelArticle.search @q, :fields => 'id'

            Tire::Search::Search.any_instance.expects(:fields).with(["id", "title"])
            ActiveModelArticle.search @q, :fields => ['id', 'title']
          end

          should "allow to pass :version option" do
            Tire::Search::Search.any_instance.expects(:version).with(true)

            ActiveModelArticle.search @q, :version => true
          end

        end

        context "multi search" do

          should "perform search request within corresponding index and type" do
            Tire::Search::Multi::Search.
              expects(:new).
              with do |index, options, block|
                assert_equal 'active_model_articles', index
                assert_equal 'active_model_article',  options[:type]
              end.
              returns( mock(:results => []) )

            ActiveModelArticle.multi_search do
              search 'foo'
              search 'xoo'
            end
          end

        end

        should "not set callback when hooks are missing" do
          @model = ActiveModelArticle.new
          @model.expects(:update_elasticsearch_index).never

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
          @model.tire.expects(:update_index)

          @model.save
        end

        should "fire :after_destroy callbacks" do
          @model = ActiveModelArticleWithCallbacks.new
          @model.tire.expects(:update_index)

          @model.destroy
        end

        should "store the record in index on :update_elasticsearch_index when saved" do
          @model = ActiveModelArticleWithCallbacks.new
          Tire::Index.any_instance.expects(:store).returns({})

          @model.save
        end

        should "remove the record from index on :update_elasticsearch_index when destroyed" do
          @model = ActiveModelArticleWithCallbacks.new
          i = mock('index') { expects(:remove) }
          Tire::Index.expects(:new).with('active_model_article_with_callbacks').returns(i)

          @model.destroy
        end

        context "with custom mapping" do

          should "create the index with mapping" do
            expected = {
              :settings => {},
              :mappings => { :model_with_custom_mapping => {
                :properties => { :title => { :type => 'string', :analyzer => 'snowball', :boost => 10 } }
              }}
            }

            Tire::Index.any_instance.expects(:create).with(expected)

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

          should "create the index with proper mapping options" do
            expected = {
              :settings => {},
              :mappings => {
                :model_with_custom_mapping_and_options => {
                  :_source    => { :compress => true  },
                  :_all       => { :enabled  => false },
                  :properties => { :title => { :type => 'string', :analyzer => 'snowball', :boost => 10 } }
                }
              }
            }

            Tire::Index.any_instance.expects(:create).with(expected)

            class ::ModelWithCustomMappingAndOptions
              extend ActiveModel::Naming
              extend ActiveModel::Callbacks

              include Tire::Model::Search
              include Tire::Model::Callbacks

              mapping :_source => { :compress => true }, :_all => { :enabled => false } do
                indexes :title, :type => 'string', :analyzer => 'snowball', :boost => 10
              end

            end

            assert_equal 'snowball', ModelWithCustomMappingAndOptions.mapping[:title][:analyzer]
            assert_equal true,       ModelWithCustomMappingAndOptions.mapping_options[:_source][:compress]
            assert_equal false,      ModelWithCustomMappingAndOptions.mapping_options[:_all][:enabled]
          end

          should "not raise an error when defining mapping" do
            Tire::Index.any_instance.unstub(:exists?)
            Configuration.client.expects(:head).raises(Errno::ECONNREFUSED)

            assert_nothing_raised do
              class ::ModelWithCustomMapping
                extend ActiveModel::Naming
                extend ActiveModel::Callbacks

                include Tire::Model::Search
                include Tire::Model::Callbacks

                mapping do
                  indexes :title, :type => 'string', :analyzer => 'snowball', :boost => 10
                end

              end
            end
          end

          should "define mapping for nested properties with a block" do
            expected = {
              :settings => {},
              :mappings => { :model_with_nested_mapping => {
                :properties => {
                  :title =>  { :type => 'string' },
                  :author => {
                    :type => 'object',
                    :properties => {
                      :first_name => { :type => 'string' },
                      :last_name  => { :type => 'string', :boost => 100 },
                      :posts => {
                        :type => 'object',
                        :properties => {
                          :title  => { :type => 'string', :boost => 10 }
                        }
                      }
                    }
                  }
                }
              }
            }}

            Tire::Index.any_instance.expects(:create).with(expected)

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

                  indexes :posts do
                    indexes :title, :type => 'string', :boost => 10
                  end
                end
              end

            end

            assert_not_nil ModelWithNestedMapping.mapping[:author][:properties][:last_name]
            assert_equal   100, ModelWithNestedMapping.mapping[:author][:properties][:last_name][:boost]
            assert_equal   10, ModelWithNestedMapping.mapping[:author][:properties][:posts][:properties][:title][:boost]
          end

          should "define mapping for nested documents" do
            class ::ModelWithNestedDocuments
              extend ActiveModel::Naming
              extend ActiveModel::Callbacks

              include Tire::Model::Search
              include Tire::Model::Callbacks

              mapping do
                indexes :comments, :type => 'nested', :include_in_parent => true do
                  indexes :author_name
                  indexes :body, :boost => 100
                end
              end

            end

            assert_equal 'nested', ModelWithNestedDocuments.mapping[:comments][:type]
            assert_not_nil         ModelWithNestedDocuments.mapping[:comments][:properties][:author_name]
            assert_equal 100,      ModelWithNestedDocuments.mapping[:comments][:properties][:body][:boost]
          end

        end

        context "with settings" do

          should "create the index with settings and mappings" do
            expected_settings = {
              :settings => { :number_of_shards => 1, :number_of_replicas => 1 }
            }

            Tire::Index.any_instance.expects(:create).with do |expected|
              expected[:settings][:number_of_shards] == 1 &&
              expected[:mappings].size > 0
            end

            class ::ModelWithCustomSettings
              extend ActiveModel::Naming
              extend ActiveModel::Callbacks

              include Tire::Model::Search
              include Tire::Model::Callbacks

              settings :number_of_shards => 1, :number_of_replicas => 1 do
                mapping do
                  indexes :title, :type => 'string'
                end
              end

            end

            assert_instance_of Hash, ModelWithCustomSettings.settings
            assert_equal 1, ModelWithCustomSettings.settings[:number_of_shards]
          end

        end

        context "with index update callbacks" do
          setup do
            class ::ModelWithIndexCallbacks
              _update_elasticsearch_index_callbacks.clear
              def notify; end
            end

            response = { 'ok'  => true,
                         '_id' => 1,
                         'matches' => ['foo'] }
            Configuration.client.expects(:post).returns(mock_response(response.to_json))
          end

          should "run the callback defined as block" do
            class ::ModelWithIndexCallbacks
              after_update_elasticsearch_index { self.go! }
            end

            @model = ::ModelWithIndexCallbacks.new
            @model.expects(:go!)

            @model.update_elasticsearch_index
          end

          should "run the callback defined as symbol" do
            class ::ModelWithIndexCallbacks
              after_update_elasticsearch_index :notify

              def notify; self.go!; end
            end

            @model = ::ModelWithIndexCallbacks.new
            @model.expects(:go!)

            @model.update_elasticsearch_index
          end

          should "set the 'matches' property from percolated response" do
            @model = ::ModelWithIndexCallbacks.new
            @model.update_elasticsearch_index

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

          should "not include the ID property in serialized document (_source)" do
            @model = ActiveModelArticle.new 'id' => 1, 'title' => 'Test'
            assert_nil MultiJson.decode(@model.to_indexed_json)[:id]
            assert_nil MultiJson.decode(@model.to_indexed_json)['id']
          end

          should "not include the type property in serialized document (_source)" do
            @model = ActiveModelArticle.new 'type' => 'foo', 'title' => 'Test'
            assert_nil MultiJson.decode(@model.to_indexed_json)[:type]
            assert_nil MultiJson.decode(@model.to_indexed_json)['type']
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
              extend  ActiveModel::Callbacks
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

          should "evaluate :as mapping options passed as strings or procs" do
            class ::ModelWithMappingProcs
              extend  ActiveModel::Naming
              extend  ActiveModel::Callbacks
              include ActiveModel::Serialization
              include Tire::Model::Search
              include Tire::Model::Callbacks

              mapping do
                indexes :one,   :type => 'string', :analyzer => 'keyword'
                indexes :two,   :type => 'string', :analyzer => 'keyword', :as => proc { one * 2 }
                indexes :three, :type => 'string', :analyzer => 'keyword', :as => 'one + 2'
              end

              attr_reader :attributes

              def initialize(attributes = {}); @attributes = attributes; end

              def method_missing(name, *args, &block)
                attributes[name.to_sym] || attributes[name.to_s] || super
              end
            end

            model    = ::ModelWithMappingProcs.new :one => 1, :two => 1, :three => 1
            hash     = model.serializable_hash
            document = MultiJson.decode(model.to_indexed_json)

            assert_equal 1, hash[:one]
            assert_equal 1, hash[:two]
            assert_equal 1, hash[:three]

            assert_equal 1, document['one']
            assert_equal 2, document['two']
            assert_equal 3, document['three']
          end

          should "index :as mapping options passed as arbitrary objects" do
            class ::ModelWithMappingOptionAsObject
              extend  ActiveModel::Naming
              extend  ActiveModel::Callbacks
              include ActiveModel::Serialization
              include Tire::Model::Search

              mapping do
                indexes :one,   :as => [1, 2, 3]
              end

              attr_reader :attributes

              def initialize(attributes = {}); @attributes = attributes; end
            end

            model    = ::ModelWithMappingOptionAsObject.new
            document = MultiJson.decode(model.to_indexed_json)

            assert_equal [1, 2, 3], document['one']
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

            Tire::Index.any_instance.expects(:percolate).with do |doc,query|
              # p [doc,query]
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

            @article.update_elasticsearch_index
          end

          should "not percolate document on index update when not set for percolation" do
            Tire::Index.any_instance.expects(:store).with do |doc,options|
              # p [doc,options]
              options[:percolate] == nil
            end.returns(MultiJson.decode('{"ok":true,"_id":"test"}'))

            @article.update_elasticsearch_index
          end

          should "set the default percolator pattern" do
            class ::ActiveModelArticleWithPercolation < ::ActiveModelArticleWithCallbacks
              percolate!
            end

            assert_equal true, ::ActiveModelArticleWithPercolation.percolator
          end

          should "set the percolator pattern" do
            class ::ActiveModelArticleWithPercolation < ::ActiveModelArticleWithCallbacks
              percolate! 'tags:alert'
            end

            assert_equal 'tags:alert', ::ActiveModelArticleWithPercolation.percolator
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
            percolated.update_elasticsearch_index
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

            percolated.update_elasticsearch_index

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

            percolated.update_elasticsearch_index

            assert_equal ['alerts'], $test__matches
          end

        end

        context "proxy" do

          should "have the proxy to class methods" do
            assert_respond_to ActiveModelArticle, :tire
            assert_instance_of Tire::Model::Search::ClassMethodsProxy, ActiveModelArticle.tire
          end

          should "have the proxy to instance methods" do
            assert_respond_to ActiveModelArticle.new, :tire
            assert_instance_of Tire::Model::Search::InstanceMethodsProxy, ActiveModelArticle.new.tire
          end

          should "NOT overload existing top-level class methods" do
            assert_equal "THIS IS MY MAPPING!", ActiveRecordClassWithTireMethods.mapping
            assert_equal 'snowball', ActiveRecordClassWithTireMethods.tire.mapping[:title][:analyzer]
          end

          should "NOT overload existing top-level instance methods" do
            ActiveRecordClassWithTireMethods.stubs(:columns).returns([])
            ActiveRecordClassWithTireMethods.stubs(:column_defaults).returns({})
            assert_equal "THIS IS MY INDEX!", ActiveRecordClassWithTireMethods.new.index
            assert_equal 'active_record_class_with_tire_methods',
                         ActiveRecordClassWithTireMethods.new.tire.index.name
          end

        end

        context "with index prefix" do
          class ::ModelWithoutPrefix
            extend ActiveModel::Naming
            extend ActiveModel::Callbacks

            include Tire::Model::Search
            include Tire::Model::Callbacks
          end
          class ::ModelWithPrefix
            extend ActiveModel::Naming
            extend ActiveModel::Callbacks

            include Tire::Model::Search
            include Tire::Model::Callbacks

            tire.index_prefix 'custom_prefix'
          end

          class ::OtherModelWithPrefix
            extend ActiveModel::Naming
            extend ActiveModel::Callbacks

            include Tire::Model::Search
            include Tire::Model::Callbacks

            index_prefix 'other_custom_prefix'
          end

          teardown do
            # FIXME: Depends on the interface itself
            Model::Search.index_prefix nil
          end

          should "return nil by default" do
            assert_nil Model::Search.index_prefix
          end

          should "allow to set and retrieve the value" do
            assert_nothing_raised { Model::Search.index_prefix 'app_environment' }
            assert_equal 'app_environment', Model::Search.index_prefix
          end

          should "allow to reset the value" do
            Model::Search.index_prefix 'prefix'
            Model::Search.index_prefix nil
            assert_nil Model::Search.index_prefix
          end

          should "not add any prefix by default" do
            assert_equal 'model_without_prefixes', ModelWithoutPrefix.index_name
          end

          should "add general and custom prefixes to model index names" do
            Model::Search.index_prefix 'general_prefix'
            assert_equal 'general_prefix_model_without_prefixes',         ModelWithoutPrefix.index_name
            assert_equal 'custom_prefix_model_with_prefixes',             ModelWithPrefix.index_name
            assert_equal 'other_custom_prefix_other_model_with_prefixes', OtherModelWithPrefix.index_name
          end

        end

        context "with dynamic index name" do
          class ::ModelWithDynamicIndexName
            extend ActiveModel::Naming
            extend ActiveModel::Callbacks

            include Tire::Model::Search
            include Tire::Model::Callbacks

            index_name do
              "dynamic" + '_' + "index"
            end
          end

          should "have index name as a proc" do
            assert_kind_of Proc, ::ModelWithDynamicIndexName.index_name
          end

          should "evaluate the proc in Model.index" do
            assert_equal 'dynamic_index', ::ModelWithDynamicIndexName.index.name
          end

        end

      end

      context "Results::Item" do

        setup do
          module ::Rails
          end

          class ::FakeRailsModel
            extend  ActiveModel::Naming
            include ActiveModel::Conversion
            def self.find(*args); new; end
          end

          @document = Results::Item.new :id => 1, :_type => 'fake_rails_model', :title => 'Test'
        end

        should "load the 'real' instance from the corresponding model" do
          assert_respond_to  @document, :load
          assert_instance_of FakeRailsModel, @document.load
        end

        should "pass the ID to the corresponding model's find method" do
          FakeRailsModel.expects(:find).with(1).returns(FakeRailsModel.new)
          @document.load
        end

        should "pass the options to the corresponding model's find method" do
          FakeRailsModel.expects(:find).with(1, {:include => 'everything'}).returns(FakeRailsModel.new)
          @document.load :include => 'everything'
        end

      end

    end

  end
end
