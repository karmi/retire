require 'test_helper'

module Slingshot
  module Model

    class PersistenceTest < Test::Unit::TestCase

      context "Model" do

        should "have index_name" do
          assert_equal 'persistent_articles', PersistentArticle.index_name
          assert_equal 'persistent_articles', PersistentArticle.new(:name => 'Test').index_name
        end

        should "have document_type" do
          assert_equal 'persistent_article', PersistentArticle.document_type
          assert_equal 'persistent_article', PersistentArticle.new(:name => 'Test').document_type
        end

      end

      context "Finders" do

        setup do
          @first  = { '_id' => 1, '_source' => { :title => 'First'  } }
          @second = { '_id' => 2, '_source' => { :title => 'Second' } }
          @third  = { '_id' => 3, '_source' => { :title => 'Third'  } }
          @find_all = { 'hits' => { 'hits' => [
            @first,
            @second,
            @third
          ] } }
          @find_first = { 'hits' => { 'hits' => [ @first ] } }
          @find_last_two = { 'hits' => { 'hits' => [ @second, @third ] } }
        end

        should "find document by numeric ID" do
          Configuration.client.expects(:get).returns(@first.to_json)
          document = PersistentArticle.find 1

          assert_instance_of PersistentArticle, document
          assert_equal 'First', document.attributes['title']
          # assert_equal 'First', document.title
        end

        should "find document by string ID" do
          Configuration.client.expects(:get).returns(@first.to_json)
          document = PersistentArticle.find '1'

          assert_instance_of PersistentArticle, document
          assert_equal 'First', document.attributes['title']
          # assert_equal 'First', document.title
        end

        should "find document by list of IDs" do
          Configuration.client.expects(:post).returns(@find_last_two.to_json)
          documents = PersistentArticle.find 2, 3

          assert_equal 2, documents.count
        end

        should "find document by array of IDs" do
          Configuration.client.expects(:post).returns(@find_last_two.to_json)
          documents = PersistentArticle.find [2, 3]

          assert_equal 2, documents.count
        end

        should "find all documents" do
          Configuration.client.stubs(:post).returns(@find_all.to_json)
          documents = PersistentArticle.all

          assert_equal 3, documents.count
          assert_equal 'First', documents.first.attributes['title']
          assert_equal PersistentArticle.find(:all).map { |e| e.id }, PersistentArticle.all.map { |e| e.id }
        end

        should "find first document" do
          Configuration.client.expects(:post).returns(@find_first.to_json)
          document = PersistentArticle.first

          assert_equal 'First', document.attributes['title']
        end

        should "raise error when passing incorrect argument" do
          assert_raise(ArgumentError) do
             PersistentArticle.find :name => 'Test'
          end
        end

      end

      context "Persistent model" do

        setup { @article = PersistentArticle.new :title => 'Test', :tags => [:one, :two] }

        should "allow to set attributes on initialization" do
          assert_not_nil @article.attributes
          assert_equal 'Test', @article.attributes[:title]
        end

        should "have getters for existing attributes" do
          assert_not_nil @article.title
          assert_equal 'Test', @article.title
          assert_equal [:one, :two], @article.tags
        end

        should "have getters for existing String attributes" do
          article = PersistentArticle.new 'title' => 'Tony Montana'
          assert_not_nil article.title
          assert_equal   'Tony Montana', article.title
        end

        should "raise error when getting unknown attributes" do
          assert_raise(NoMethodError) do
            @article.krapulitz
          end
        end

        should_eventually "not raise error when getting known attribute" do
          article = PersistentArticle.new :title => 'Test'
          article.class_eval do
            property :title, :tags
          end

          assert_nothing_raised { article.tags }
          assert_nil article.tags
        end

        should_eventually "return default values for known attribute" do
          article = PersistentArticle.new :title => 'Test'
          article.class_eval do
            property :title
            property :tags, :default => []
          end

          assert_nothing_raised { article.tags }
          assert_equal [], article.tags
        end

        should "have query method for existing attribute" do
          assert_equal true, @article.title?
        end

        should "raise error when querying for unknown attribute" do
          assert_raise(NoMethodError) do
            @article.krapulitz?
          end
        end

        should_eventually "not raise error when querying for known attribute" do
          article = PersistentArticle.new :title => 'Test'
          article.class_eval do
            property :title, :published
          end

          assert_nothing_raised { article.published? }
          assert ! article.published?
        end
      
        should "return true for respond_to? calls for existing attributes" do
          article = PersistentArticle.new :title => 'Test'
          assert article.respond_to?(:title)
        end

        should "return true for respond_to? calls for unknown attributes" do
          article = PersistentArticle.new :title => 'Test'
          assert ! article.respond_to?(:krapulitz)
        end

        should_eventually "return true for respond_to? calls for known attributes" do
          article = PersistentArticle.new :title => 'Test'
          article.class_eval do
            property :title, :published
          end

          assert article.respond_to?(:published)
        end

        should "have attribute names" do
          article = PersistentArticle.new :one => 'One', :two => 'Two'
          assert_equal ['one', 'two'], article.attribute_names
        end

        should "allow to update existing attribute" do
          @article.title = 'Updated'
          assert_equal 'Updated', @article.title
          assert_equal 'Updated', @article.attributes[:title]
        end

        should "allow to set new attribute" do
          @article.author = 'John Smith'
          assert_equal 'John Smith', @article.author
          assert_equal 'John Smith', @article.attributes[:author]
        end

        should_eventually "allow to set deeply nested attributes" do
          @article.author.first_name = 'John'
          @article.author.last_name  = 'Smith'

          assert_equal 'John',  @article.author.first_name
          assert_equal 'Smith', @article.author.last_name
          assert_equal({ :first_name => 'John', :last_name => 'Smith' }, @article.attributes[:author])
        end

        context "when creating" do

          should "save the document with generated ID in the database" do
            Configuration.client.expects(:post).with("#{Configuration.url}/persistent_articles/persistent_article/",
                                                     '{"title":"Test","tags":["one","two"]}').
                                                returns('{"ok":true,"_id":"abc123"}')
            article = PersistentArticle.create :title => 'Test', :tags => [:one, :two]
            assert article.persisted?, "#{article.inspect} should be `persisted?`"
            assert_equal 'abc123', article.id
          end

          should "save the document with custom ID in the database" do
            Configuration.client.expects(:post).with("#{Configuration.url}/persistent_articles/persistent_article/r2d2",
                                                     {:id => 'r2d2', :title => 'Test'}.to_json).
                                                returns('{"ok":true,"_id":"r2d2"}')
            article = PersistentArticle.create :id => 'r2d2', :title => 'Test'
            assert_equal 'r2d2', article.id
          end

        end

        context "when saving" do

          should "save the document with updated attribute" do
            Configuration.client.expects(:post).with("#{Configuration.url}/persistent_articles/persistent_article/1",
                                                     {:id => 1, :title => 'Test', :tags => ['one', 'two']}.to_json).
                                                returns('{"ok":true,"_id":"1"}')
            Configuration.client.expects(:post).with("#{Configuration.url}/persistent_articles/persistent_article/1",
                                                     {:id => 1, :title => 'Updated', :tags => ['one', 'two']}.to_json).
                                                returns('{"ok":true,"_id":"1"}')
            article = PersistentArticle.new :id => 1, :title => 'Test', :tags => [:one, :two]
            assert article.save

            article.title = 'Updated'
            assert article.save
          end

        end

        context "when destroying" do

          should "delete the document from the database" do
            Configuration.client.expects(:post).with("#{Configuration.url}/persistent_articles/persistent_article/1",
                                                     {:id => 1, :title => 'Test'}.to_json).
                                                returns('{"ok":true,"_id":"1"}')
            Configuration.client.expects(:delete).with("#{Configuration.url}/persistent_articles/persistent_article/1")

            article = PersistentArticle.new :id => 1, :title => 'Test'
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

    end
  end
end
