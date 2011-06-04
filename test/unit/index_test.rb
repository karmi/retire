require 'test_helper'

module Tire

  class IndexTest < Test::Unit::TestCase

    context "Index" do

      setup do
        @index = Tire::Index.new 'dummy'
      end

      should "have a name" do
        assert_equal 'dummy', @index.name
      end

      should "return true when exists" do
        Configuration.client.expects(:get).returns(mock_response('{"dummy":{"document":{"properties":{}}}}'))
        assert @index.exists?
      end

      should "return false when does not exist" do
        Configuration.client.expects(:get).raises(RestClient::ResourceNotFound)
        assert ! @index.exists?
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

      should "open the index" do
        Configuration.client.expects(:post).returns(mock_response('{"ok":true,"_shards":{}}'))
        assert_nothing_raised { assert @index.open }
      end

      should "close the index" do
        Configuration.client.expects(:post).returns(mock_response('{"ok":true,"_shards":{}}'))
        assert_nothing_raised { assert @index.close }
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
                                                     MultiJson.encode({:id => 123, :title => 'Test'})).
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

      context "when storing in bulk" do
        # The expected JSON looks like this:
        #
        # {"index":{"_index":"dummy","_type":"document","_id":"1"}}
        # {"id":"1","title":"One"}
        # {"index":{"_index":"dummy","_type":"document","_id":"2"}}
        # {"id":"2","title":"Two"}
        #
        # See http://www.elasticsearch.org/guide/reference/api/bulk.html

        should "serialize Hashes" do
          Configuration.client.expects(:post).with do |url, json|
            url  == "#{Configuration.url}/_bulk"
            json =~ /"_index":"dummy"/
            json =~ /"_type":"document"/
            json =~ /"_id":"1"/
            json =~ /"_id":"2"/
            json =~ /"id":"1"/
            json =~ /"id":"2"/
            json =~ /"title":"One"/
            json =~ /"title":"Two"/
          end.returns('{}')

          @index.bulk_store [ {:id => '1', :title => 'One'}, {:id => '2', :title => 'Two'} ]

        end

        should "serialize ActiveModel instances" do
          Configuration.client.expects(:post).with do |url, json|
            url  == "#{Configuration.url}/_bulk"
            json =~ /"_index":"active_model_articles"/
            json =~ /"_type":"article"/
            json =~ /"_id":"1"/
            json =~ /"_id":"2"/
            json =~ /"id":"1"/
            json =~ /"id":"2"/
            json =~ /"title":"One"/
            json =~ /"title":"Two"/
          end.returns('{}')

          one = ActiveModelArticle.new 'title' => 'One'; one.id = '1'
          two = ActiveModelArticle.new 'title' => 'Two'; two.id = '2'

          ActiveModelArticle.elasticsearch_index.bulk_store [ one, two ]

        end

        should "try again when an exception occurs" do
          Configuration.client.expects(:post).raises(RestClient::RequestFailed).at_least(2)

          assert_raise(RestClient::RequestFailed) do
            @index.bulk_store [ {:id => '1', :title => 'One'}, {:id => '2', :title => 'Two'} ]
          end
        end

        should_eventually "raise exception when collection item does not have ID" do
          # TODO: raise exception when collection item does not have ID
        end

      end

      context "when importing" do
        setup do
          @index = Tire::Index.new 'import'
        end

        class ::ImportData
          DATA = (1..4).to_a

          def self.paginate(options={})
            options = {:page => 1, :per_page => 1000}.update options
            DATA.slice( (options[:page]-1)*options[:per_page]...options[:page]*options[:per_page] )
          end

          def self.each(&block);   DATA.each &block; end
          def self.map(&block);    DATA.map &block;  end
          def self.count;          DATA.size;        end
        end

        should "be initialized with a collection" do
          @index.expects(:bulk_store).returns(:true)

          assert_nothing_raised { @index.import [{ :id => 1, :title => 'Article' }] }
        end

        should "be initialized with a class and params" do
          @index.expects(:bulk_store).returns(:true)

          assert_nothing_raised { @index.import ImportData }
        end

        context "plain collection" do

          should "just store it in bulk" do
            collection = [{ :id => 1, :title => 'Article' }]
            @index.expects(:bulk_store).with( collection ).returns(true)

            @index.import collection
          end

        end

        context "class" do

          should "call the passed method and bulk store the results" do
            @index.expects(:bulk_store).with([1, 2, 3, 4]).returns(true)

            @index.import ImportData, :paginate
          end

          should "pass the params to the passed method and bulk store the results" do
            @index.expects(:bulk_store).with([1, 2]).returns(true)
            @index.expects(:bulk_store).with([3, 4]).returns(true)

            @index.import ImportData, :paginate, :page => 1, :per_page => 2
          end

          should "pass the class when method not passed" do
            @index.expects(:bulk_store).with(ImportData).returns(true)

            @index.import ImportData
          end

        end

        context "with passed block" do

          context "and plain collection" do

            should "allow to manipulate the collection in the block" do
              Tire::Index.any_instance.expects(:bulk_store).with([{ :id => 1, :title => 'ARTICLE' }])


              @index.import [{ :id => 1, :title => 'Article' }] do |articles|
                articles.map { |article| article.update :title => article[:title].upcase }
              end
            end

          end

          context "and object" do

            should "call the passed block on every batch" do
              Tire::Index.any_instance.expects(:bulk_store).with([1, 2])
              Tire::Index.any_instance.expects(:bulk_store).with([3, 4])

              runs = 0
              @index.import ImportData, :paginate, :per_page => 2 do |documents|
                runs += 1
                # Don't forget to return the documents at the end of the block
                documents
              end

              assert_equal 2, runs
            end

            should "allow to manipulate the documents in passed block" do
              Tire::Index.any_instance.expects(:bulk_store).with([2, 3])
              Tire::Index.any_instance.expects(:bulk_store).with([4, 5])


              @index.import ImportData, :paginate, :per_page => 2 do |documents|
                # Add 1 to every "document" and return them
                documents.map { |d| d + 1 }
              end
            end

          end

        end

      end

    end

  end

end
