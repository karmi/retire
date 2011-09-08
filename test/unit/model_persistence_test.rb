require 'test_helper'

module Tire
  module Model

    class PersistenceTest < Test::Unit::TestCase

      context "Model" do

        should "have default index name" do
          assert_equal 'persistent_articles', PersistentArticle.index_name
          assert_equal 'persistent_articles', PersistentArticle.new(:title => 'Test').index_name
        end

        should "allow to set custom index name" do
          assert_equal 'custom-index-name', PersistentArticleWithCustomIndexName.index_name

          PersistentArticleWithCustomIndexName.index_name "another-index-name"
          assert_equal 'another-index-name', PersistentArticleWithCustomIndexName.index_name
          assert_equal 'another-index-name', PersistentArticleWithCustomIndexName.index.name
        end

        context "with index_prefix configured" do
          setup do
            PersistentArticle.instance_variable_set(:@index_name, nil)
            Model::Search.index_prefix 'prefix_'
          end
          
          teardown do
            Model::Search.instance_variable_set(:@index_prefix, nil)
            PersistentArticle.instance_variable_set(:@index_name, nil)
          end
          
          should "have configured prefix in index_name" do
            assert_equal 'prefix_persistent_articles', PersistentArticle.index_name
            assert_equal 'prefix_persistent_articles', PersistentArticle.new(:title => 'Test').index_name
          end
          
        end

        should "have document_type" do
          assert_equal 'persistent_article', PersistentArticle.document_type
          assert_equal 'persistent_article', PersistentArticle.new(:title => 'Test').document_type
        end

        should "allow to define property" do
          assert_nothing_raised do
            a = PersistentArticle.new
            class << a
              property :status
            end
          end
        end

      end

      context "Finders" do

        setup do
          @first  = { '_id' => 1, '_version' => 1, '_index' => 'persistent_articles', '_type' => 'persistent_article', '_source' => { :title => 'First'  } }
          @second = { '_id' => 2, '_index' => 'persistent_articles', '_type' => 'persistent_article', '_source' => { :title => 'Second' } }
          @third  = { '_id' => 3, '_index' => 'persistent_articles', '_type' => 'persistent_article', '_source' => { :title => 'Third'  } }
          @find_all = { 'hits' => { 'hits' => [
            @first,
            @second,
            @third
          ] } }
          @find_first = { 'hits' => { 'hits' => [ @first ] } }
          @find_last_two = { 'hits' => { 'hits' => [ @second, @third ] } }
        end

        should "find document by numeric ID" do
          Configuration.client.expects(:get).returns(mock_response(@first.to_json))
          document = PersistentArticle.find 1

          assert_instance_of PersistentArticle, document
          assert_equal 1, document.id
          assert_equal 1, document.attributes['id']
          assert_equal 'First', document.attributes['title']
          assert_equal 'First', document.title
        end

        should "have _type, _index, _id, _version attributes" do
          Configuration.client.expects(:get).returns(mock_response(@first.to_json))
          document = PersistentArticle.find 1

          assert_instance_of PersistentArticle, document
          assert_equal 1, document.id
          assert_equal 1, document.attributes['id']
          assert_equal 'persistent_articles', document._index
          assert_equal 'persistent_article', document._type
          assert_equal 1, document._version
        end

        should "find document by string ID" do
          Configuration.client.expects(:get).returns(mock_response(@first.to_json))
          document = PersistentArticle.find '1'

          assert_instance_of PersistentArticle, document
          assert_equal 1, document.id
          assert_equal 1, document.attributes['id']
          assert_equal 'First', document.attributes['title']
          assert_equal 'First', document.title
        end

        should "find document by list of IDs" do
          Configuration.client.expects(:get).returns(mock_response(@find_last_two.to_json))
          documents = PersistentArticle.find 2, 3

          assert_equal 2, documents.count
        end

        should "find document by array of IDs" do
          Configuration.client.expects(:get).returns(mock_response(@find_last_two.to_json))
          documents = PersistentArticle.find [2, 3]

          assert_equal 2, documents.count
        end

        should "find all documents" do
          Configuration.client.stubs(:get).returns(mock_response(@find_all.to_json))
          documents = PersistentArticle.all

          assert_equal 3, documents.count
          assert_equal 'First', documents.first.attributes['title']
          assert_equal PersistentArticle.find(:all).map { |e| e.id }, PersistentArticle.all.map { |e| e.id }
        end

        should "find first document" do
          Configuration.client.expects(:get).returns(mock_response(@find_first.to_json))
          document = PersistentArticle.first

          assert_equal 'First', document.attributes['title']
        end

        should "raise error when passing incorrect argument" do
          assert_raise(ArgumentError) do
             PersistentArticle.find :name => 'Test'
          end
        end

        should_eventually "raise error when document is not found" do
          assert_raise(DocumentNotFound) do
             PersistentArticle.find 'xyz001'
          end
        end

      end

      context "Persistent model" do

        setup { @article = PersistentArticle.new :title => 'Test', :tags => [:one, :two] }

        context "attribute methods" do

          should "allow to set attributes on initialization" do
            assert_not_nil @article.attributes
            assert_equal 'Test', @article.attributes['title']
          end

          should "allow to leave attributes blank on initialization" do
            assert_nothing_raised { PersistentArticle.new }
          end

          should "have getter methods for attributes" do
            assert_not_nil @article.title
            assert_equal 'Test', @article.title
            assert_equal [:one, :two], @article.tags
          end

          should "have getter methods for attribute passed as a String" do
            article = PersistentArticle.new 'title' => 'Tony Montana'
            assert_not_nil article.title
            assert_equal   'Tony Montana', article.title
          end

          should "raise error when getting unknown attribute" do
            assert_raise(NoMethodError) do
              @article.krapulitz
            end
          end

          should "not raise error when getting unset attribute" do
            article = PersistentArticle.new :title => 'Test'

            assert_nothing_raised { article.published_on }
            assert_nil article.published_on
          end

          should_eventually "return default value for attribute" do
            article = PersistentArticle.new :title => 'Test'
            article.class_eval do
              property :title
              property :tags, :default => []
            end

            assert_nothing_raised { article.tags }
            assert_equal [], article.tags
          end

          should "have query method for attribute" do
            assert_equal true, @article.title?
          end

          should "raise error when querying for unknown attribute" do
            assert_raise(NoMethodError) do
              @article.krapulitz?
            end
          end

          should "not raise error when querying for unset attribute" do
            article = PersistentArticle.new :title => 'Test'

            assert_nothing_raised { article.published_on? }
            assert ! article.published_on?
          end

          should "return true for respond_to? calls for set attributes" do
            article = PersistentArticle.new :title => 'Test'
            assert article.respond_to?(:title)
          end

          should "return false for respond_to? calls for unknown attributes" do
            article = PersistentArticle.new :title => 'Test'
            assert ! article.respond_to?(:krapulitz)
          end

          should "return true for respond_to? calls for defined but unset attributes" do
            article = PersistentArticle.new :title => 'Test'

            assert article.respond_to?(:published_on)
          end

          should "have attribute names" do
            article = PersistentArticle.new :title => 'Test', :tags => ['one', 'two']
            assert_equal ['published_on', 'tags', 'title'], article.attribute_names
          end

          should "have setter method for attribute" do
            @article.title = 'Updated'
            assert_equal 'Updated', @article.title
            assert_equal 'Updated', @article.attributes['title']
          end

          should_eventually "allow to set deeply nested attributes on initialization" do
            article = PersistentArticle.new :title => 'Test', :author => { :first_name => 'John', :last_name => 'Smith' }

            assert_equal 'John',  article.author.first_name
            assert_equal 'Smith', article.author.last_name
            assert_equal({ :first_name => 'John', :last_name => 'Smith' }, article.attributes['author'])
          end

          should_eventually "allow to set deeply nested attributes on update" do
            article = PersistentArticle.new :title => 'Test', :author => { :first_name => 'John', :last_name => 'Smith' }

            article.author.first_name = 'Robert'
            article.author.last_name  = 'Carpenter'

            assert_equal 'Robert',    article.author.first_name
            assert_equal 'Carpenter', article.author.last_name
            assert_equal({ :first_name => 'Robert', :last_name => 'Carpenter' }, article.attributes['author'])
          end

        end

        context "when creating" do

          should "save the document with generated ID in the database" do
            Configuration.client.expects(:post).
                                 with do |url, payload|
                                  doc = MultiJson.decode(payload)
                                  url == "#{Configuration.url}/persistent_articles/persistent_article/" &&
                                  doc['title'] == 'Test' &&
                                  doc['tags']  == ['one', 'two']
                                  doc['published_on'] == nil
                                end.
                                returns(mock_response('{"ok":true,"_id":"abc123"}'))
            article = PersistentArticle.create :title => 'Test', :tags => [:one, :two]

            assert article.persisted?, "#{article.inspect} should be `persisted?`"
            assert_equal 'abc123', article.id
          end

          should "save the document with custom ID in the database" do
            Configuration.client.expects(:post).
                                 with do |url, payload|
                                   doc = MultiJson.decode(payload)
                                   url == "#{Configuration.url}/persistent_articles/persistent_article/r2d2" &&
                                   doc['id'] == 'r2d2' &&
                                   doc['title'] == 'Test' &&
                                   doc['published_on'] == nil
                                 end.
                                 returns(mock_response('{"ok":true,"_id":"r2d2"}'))
            article = PersistentArticle.create :id => 'r2d2', :title => 'Test'

            assert_equal 'r2d2', article.id
          end

          should "perform model validations" do
            Configuration.client.expects(:post).never

            assert ! ValidatedModel.create(:name => nil)
          end

        end

        context "when creating" do

          should "set the id property" do
            Configuration.client.expects(:post).
                                 with do |url, payload|
                                   doc = MultiJson.decode(payload)
                                   url == "#{Configuration.url}/persistent_articles/persistent_article/" &&
                                   doc['id'] == nil &&
                                   doc['title'] == 'Test'
                                 end.
                                 returns(mock_response('{"ok":true,"_id":"1"}'))

            article = PersistentArticle.create :title => 'Test'
            assert_equal '1', article.id
          end

          should "not set the id property if already set" do
            Configuration.client.expects(:post).
                                  with do |url, payload|
                                    doc = MultiJson.decode(payload)
                                    url == "#{Configuration.url}/persistent_articles/persistent_article/123" &&
                                    doc['id'] == '123' &&
                                    doc['title'] == 'Test' &&
                                    doc['published_on'] == nil
                                  end.
                                  returns(mock_response('{"ok":true, "_id":"XXX"}'))

            article = PersistentArticle.create :id => '123', :title => 'Test'
            assert_equal '123', article.id
          end

        end

        context "when saving" do

          should "save the document with updated attribute" do
            article = PersistentArticle.new :id => '1', :title => 'Test'

            Configuration.client.expects(:post).
                                 with do |url, payload|
                                   doc = MultiJson.decode(payload)
                                   url == "#{Configuration.url}/persistent_articles/persistent_article/1" &&
                                   doc['id'] == '1' &&
                                   doc['title'] == 'Test' &&
                                   doc['published_on'] == nil
                                 end.
                                 returns(mock_response('{"ok":true,"_id":"1"}'))
            assert article.save

            article.title = 'Updated'

            Configuration.client.expects(:post).
                                 with do |url, payload|
                                   doc = MultiJson.decode(payload)
                                   url == "#{Configuration.url}/persistent_articles/persistent_article/1" &&
                                   doc['id'] == '1' &&
                                   doc['title'] == 'Updated'
                                 end.
                                 returns(mock_response('{"ok":true,"_id":"1"}'))
            assert article.save
          end

          should "perform validations" do
            article = ValidatedModel.new :name => nil
            assert ! article.save
          end

          should "set the id property" do
            article = PersistentArticle.new
            article.title = 'Test'

            Configuration.client.expects(:post).with("#{Configuration.url}/persistent_articles/persistent_article/",
                                                     article.to_indexed_json).
                                                returns(mock_response('{"ok":true,"_id":"1"}'))
             assert article.save
             assert_equal '1', article.id
          end

          should "not set the id property if already set" do
            article = PersistentArticle.new
            article.id    = '456'
            article.title = 'Test'

            Configuration.client.expects(:post).
                                 with do |url, payload|
                                   doc = MultiJson.decode(payload)
                                   url == "#{Configuration.url}/persistent_articles/persistent_article/456" &&
                                   doc['id'] == '456' &&
                                   doc['title'] == 'Test'
                                 end.
                                 returns(mock_response('{"ok":true,"_id":"XXX"}'))
             assert article.save
             assert_equal '456', article.id
          end

        end

        context "when destroying" do

          should "delete the document from the database" do
            Configuration.client.expects(:post).
                                 with do |url, payload|
                                   doc = MultiJson.decode(payload)
                                   url == "#{Configuration.url}/persistent_articles/persistent_article/123" &&
                                   doc['id'] == '123' &&
                                   doc['title'] == 'Test'
                                 end.returns(mock_response('{"ok":true,"_id":"123"}'))

            Configuration.client.expects(:delete).
                                 with("#{Configuration.url}/persistent_articles/persistent_article/123")

            article = PersistentArticle.new :id => '123', :title => 'Test'
            article.save
            article.destroy
          end

        end

        context "when updating attributes" do

          should "update single attribute" do
            @article.expects(:save).returns(true)

            @article.update_attribute :title, 'Updated'
            assert_equal 'Updated', @article.title
          end

          should "update all attributes" do
            @article.expects(:save).returns(true)

            @article.update_attributes :title => 'Updated', :tags => ['three']
            assert_equal 'Updated', @article.title
            assert_equal ['three'], @article.tags
          end

        end

      end

      context "Persistent model with mapping definition" do

        should "create the index with mapping" do
          expected = {
            :settings => {},
            :mappings => { :persistent_article_with_mapping => {
              :properties => { :title => { :type => 'string', :analyzer => 'snowball', :boost => 10 } }
            }}
          }

          Tire::Index.any_instance.expects(:create).with(expected)

          class ::PersistentArticleWithMapping

            include Tire::Model::Persistence
            include Tire::Model::Search
            include Tire::Model::Callbacks

            mapping do
              property :title, :type => 'string', :analyzer => 'snowball', :boost => 10
            end

          end

          assert_equal 'snowball', PersistentArticleWithMapping.mapping[:title][:analyzer]
        end

      end

    end
  end
end
