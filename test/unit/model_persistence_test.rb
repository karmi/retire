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

        should "find all documents" do
          Configuration.client.stubs(:post).returns(@find_all.to_json)
          documents = PersistentArticle.all

          assert_equal 3, documents.count
          assert_equal 'First', documents.first.attributes['title']
          assert_equal PersistentArticle.find(:all).map { |e| e.id }, PersistentArticle.all.map { |e| e.id }
        end

        should "find first document" do
          Configuration.client.expects(:post).returns(@find_first.to_json)
          documents = PersistentArticle.first

          assert_equal 1, documents.count
          assert_equal 'First', documents.first.attributes['title']
        end


        should "raise error when passing incorrect argument" do
          assert_raise(ArgumentError) do
             PersistentArticle.find :name => 'Test'
          end
        end

      end

    end
  end
end
