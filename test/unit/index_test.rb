require 'test_helper'

module Slingshot

  class IndexTest < Test::Unit::TestCase

    context "Index" do

      setup do
        @index = Slingshot::Index.new 'dummy'
      end

      should "have a name" do
        assert_equal 'dummy', @index.name
      end

      should "create new index" do
        Configuration.client.expects(:post).returns(mock_response('{"ok":true,"acknowledged":true}'))
        assert @index.create
      end

      should "not raise exception and just return false when trying to create existing index" do
        Configuration.client.expects(:post).raises(RestClient::BadRequest)
        assert_nothing_raised { assert ! @index.create }
      end

      should "delete index" do
        Configuration.client.expects(:delete).returns(mock_response('{"ok":true,"acknowledged":true}'))
        assert @index.delete
      end

      should "not raise exception and just return false when deleting non-existing index" do
        Configuration.client.expects(:delete).returns(mock_response('{"error":"[articles] missing"}'))
        assert_nothing_raised { assert ! @index.delete }
        Configuration.client.expects(:delete).raises(RestClient::BadRequest)
        assert_nothing_raised { assert ! @index.delete }
      end

      should "refresh the index" do
        Configuration.client.expects(:post).returns(mock_response('{"ok":true,"_shards":{}}'))
        assert_nothing_raised { assert @index.refresh }
      end

      context "mapping" do

        should "create index with mapping" do
          Configuration.client.expects(:post).returns(mock_response('{"ok":true,"acknowledged":true}'))

          assert @index.create :settings => { :number_of_shards => 1 },
                               :mappings => { :article => {
                                                :properties => {
                                                  :title => { :boost => 2.0,
                                                              :type => 'string',
                                                              :store => 'yes',
                                                              :analyzer => 'snowball' }
                                                }
                                              }
                                            }
        end

        should "return the mapping" do
          json =<<-JSON
          {
            "dummy" : {
              "article" : {
                "properties" : {
                  "title" :    { "type" : "string", "boost" : 2.0 },
                  "category" : { "type" : "string", "analyzed" : "no" }
                }
              }
            }
          }
          JSON
          Configuration.client.stubs(:get).returns(mock_response(json))

          assert_equal 'string', @index.mapping['article']['properties']['title']['type']
          assert_equal 2.0,      @index.mapping['article']['properties']['title']['boost']
        end

      end

      context "when storing" do

        should "properly set type from args" do
          Configuration.client.expects(:post).with("#{Configuration.url}/dummy/article/", '{"title":"Test"}').returns(mock_response('{"ok":true,"_id":"test"}')).twice
          @index.store 'article', :title => 'Test'
          @index.store :article,  :title => 'Test'
        end

        should "set default type" do
          Configuration.client.expects(:post).with("#{Configuration.url}/dummy/document/", '{"title":"Test"}').returns(mock_response('{"ok":true,"_id":"test"}'))
          @index.store :title => 'Test'
        end

        should "call #to_indexed_json on non-String documents" do
          document = { :title => 'Test' }
          Configuration.client.expects(:post).returns(mock_response('{"ok":true,"_id":"test"}'))
          document.expects(:to_indexed_json)
          @index.store document
        end

        should "raise error when storing neither String nor object with #to_indexed_json method" do
          class MyDocument;end; document = MyDocument.new
          assert_raise(ArgumentError) { @index.store document }
        end

        context "document with ID" do

          should "store Hash it under its ID property" do
            Configuration.client.expects(:post).with("#{Configuration.url}/dummy/document/123",
                                                     Yajl::Encoder.encode({:id => 123, :title => 'Test'})).
                                                returns(mock_response('{"ok":true,"_id":"123"}'))
            @index.store :id => 123, :title => 'Test'
          end

          should "store a custom class under its ID property" do
            Configuration.client.expects(:post).with("#{Configuration.url}/dummy/document/123",
                                                     {:id => 123, :title => 'Test', :body => 'Lorem'}.to_json).
                                                returns(mock_response('{"ok":true,"_id":"123"}'))
            @index.store Article.new(:id => 123, :title => 'Test', :body => 'Lorem')
          end

        end

      end

      context "when retrieving" do

        setup do
          Configuration.reset :wrapper

          Configuration.client.stubs(:post).with("#{Configuration.url}/dummy/article/", '{"title":"Test"}').
                                            returns(mock_response('{"ok":true,"_id":"id-1"}'))
          @index.store :article, :title => 'Test'
        end

        should "return document in default wrapper" do
          Configuration.client.expects(:get).with("#{Configuration.url}/dummy/article/id-1").
                                             returns(mock_response('{"_id":"id-1","_version":1, "_source" : {"title":"Test"}}'))
          article = @index.retrieve :article, 'id-1'
          assert_instance_of Results::Item, article
          assert_equal 'Test', article.title
          assert_equal 'Test', article[:title]
        end

        should "return document as a hash" do
          Configuration.wrapper Hash

          Configuration.client.expects(:get).with("#{Configuration.url}/dummy/article/id-1").
                                             returns(mock_response('{"_id":"id-1","_version":1, "_source" : {"title":"Test"}}'))
          article = @index.retrieve :article, 'id-1'
          assert_instance_of Hash, article
        end

        should "return document in custom wrapper" do
          Configuration.wrapper Article

          Configuration.client.expects(:get).with("#{Configuration.url}/dummy/article/id-1").
                                             returns(mock_response('{"_id":"id-1","_version":1, "_source" : {"title":"Test"}}'))
          article = @index.retrieve :article, 'id-1'
          assert_instance_of Article, article
          assert_equal 'Test', article.title
        end

      end

      context "when removing" do

        should "properly set type from args" do
          Configuration.client.expects(:delete).with("#{Configuration.url}/dummy/article/").
                                                returns('{"ok":true,"_id":"test"}').twice
          @index.remove 'article', :title => 'Test'
          @index.remove :article,  :title => 'Test'
        end

        should "set default type" do
          Configuration.client.expects(:delete).with("#{Configuration.url}/dummy/document/").
                                                returns('{"ok":true,"_id":"test"}')
          @index.remove :title => 'Test'
        end

        should "get ID from hash" do
          Configuration.client.expects(:delete).with("#{Configuration.url}/dummy/document/1").
                                                returns('{"ok":true,"_id":"1"}')
          @index.remove :id => 1
        end

        should "get ID from method" do
          document = stub('document', :id => 1)
          Configuration.client.expects(:delete).with("#{Configuration.url}/dummy/document/1").
                                                returns('{"ok":true,"_id":"1"}')
          @index.remove document
        end

        should "get ID from arguments" do
          Configuration.client.expects(:delete).with("#{Configuration.url}/dummy/document/1").
                                                returns('{"ok":true,"_id":"1"}')
          @index.remove :document, 1
        end

      end

    end

  end

end
