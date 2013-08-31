require 'test_helper'

module Tire

  class ResultsCollectionTest < Test::Unit::TestCase

    context "Collection" do
      setup do
        begin; Object.send(:remove_const, :Rails); rescue; end
        Configuration.reset
        @default_response = { 'hits' => { 'hits' => [{'_id' => 1, '_score' => 1, '_source' => {:title => 'Test', :author => 'John'}},
                                                     {'_id' => 2},
                                                     {'_id' => 3}],
                                          'max_score' => 1.0 } }
      end

      should "be iterable" do
        assert_respond_to Results::Collection.new(@default_response), :each
        assert_respond_to Results::Collection.new(@default_response), :size
        assert_nothing_raised do
          Results::Collection.new(@default_response).each { |item| item.id + 1 }
          Results::Collection.new(@default_response).map  { |item| item.id + 1 }
        end
      end

      should "have size/length" do
        assert_equal 3, Results::Collection.new(@default_response).size
        assert_equal 3, Results::Collection.new(@default_response).length
      end

      should "allow access to items" do
        assert_not_nil  Results::Collection.new(@default_response)[1]
        assert_equal 2, Results::Collection.new(@default_response)[1][:id]
      end

      should "allow slicing" do
        assert_equal [2,3], Results::Collection.new(@default_response)[1,2].map  {|res| res[:id]}
        assert_equal [3],   Results::Collection.new(@default_response)[-1,1].map {|res| res[:id]}
      end

      should "be initialized with parsed JSON" do
        assert_nothing_raised do
          collection = Results::Collection.new( @default_response )
          assert_equal 3, collection.results.count
        end
      end

      should "return success/failure state" do
        assert Results::Collection.new( @default_response ).success?
      end

      should "be populated lazily" do
        collection = Results::Collection.new(@default_response)
        assert_nil collection.instance_variable_get(:@results)
      end

      should "store passed options" do
        collection = Results::Collection.new( @default_response, :per_page => 20, :page => 2 )
        assert_equal 20, collection.options[:per_page]
        assert_equal 2,  collection.options[:page]
      end

      should "be will_paginate compatible" do
        collection = Results::Collection.new(@default_response)
        %w(total_pages offset current_page per_page total_entries).each do |method|
          assert_respond_to collection, method
        end
      end

      should "be kaminari compatible" do
        collection = Results::Collection.new(@default_response)
        %w(limit_value total_count num_pages offset_value first_page? last_page? out_of_range?).each do |method|
          assert_respond_to collection, method
        end
      end

      should "have max_score" do
        collection = Results::Collection.new(@default_response)
        assert_equal 1.0, collection.max_score
      end

      should "return an array" do
        collection = Results::Collection.new(@default_response)
        assert_instance_of Array, collection.to_ary
      end

      context "serialization" do

        should "be serialized to JSON" do
          collection = Results::Collection.new(@default_response)
          assert_instance_of Array, collection.as_json
          assert_equal 'Test', collection.as_json.first['title']
          assert_equal 'John', collection.as_json.first['author']
        end

        should "pass options to as_json" do
          collection = Results::Collection.new(@default_response)
          assert_equal 'Test', collection.as_json(:only => 'title').first['title']
          assert_nil           collection.as_json(:only => 'title').first['author']
        end

      end

      context "with error response" do
        setup do
          @collection = Results::Collection.new({'error' => 'SearchPhaseExecutionException...'})
        end

        should "return the error" do
          assert_equal 'SearchPhaseExecutionException...', @collection.error
        end

        should "return the success/failure state" do
          assert @collection.failure?
        end

        should "return empty results" do
          assert @collection.empty?
        end
      end

      context "wrapping results" do

        setup do
          @response = { 'hits' => { 'hits' => [ { '_id' => 1, '_score' => 0.5, '_index' => 'testing', '_type' => 'article', '_source' => { :title => 'Test', :body => 'Lorem' } } ] } }
        end

        should "wrap hits in Item by default" do
          document =  Results::Collection.new(@response).first
          assert_kind_of Results::Item, document
          assert_equal 'Test', document.title
        end

        should "NOT allow access to raw underlying Hash in Item" do
          document = Results::Collection.new(@response).first
          assert_nil document[:_source]
          assert_nil document['_source']
        end

        should "allow wrapping hits in a Hash" do
          Configuration.wrapper(Hash)

          document =  Results::Collection.new(@response).first
          assert_kind_of Hash, document
          assert_raise(NoMethodError) { document.title }
          assert_equal   'Test', document['_source'][:title]
        end

        should "allow wrapping hits in custom class" do
          Configuration.wrapper(Article)

          article =  Results::Collection.new(@response).first
          assert_kind_of Article, article
          assert_equal   'Test',  article.title
        end

        should "return score" do
          document =  Results::Collection.new(@response).first
          assert_equal 0.5, document._score
        end

        should "return id" do
          document =  Results::Collection.new(@response).first
          assert_equal 1, document.id
        end

        should "return index" do
          document =  Results::Collection.new(@response).first
          assert_equal "testing", document._index
        end

        should "return type" do
          document =  Results::Collection.new(@response).first
          assert_equal "article", document._type
        end

        should "properly decode type" do
          @response = { 'hits' => { 'hits' => [ { '_id' => 1, '_type' => 'foo%2Fbar' } ] } }
          document =  Results::Collection.new(@response).first
          assert_equal "foo/bar", document._type
        end

      end

      context "wrapping results with selected fields" do
        # When limiting fields from _source to return ES returns them prefixed, not as "real" Hashes.
        # Underlying issue: https://github.com/karmi/tire/pull/31#issuecomment-1340967
        #
        setup do
          Configuration.reset
          @default_response = { 'hits' => { 'hits' =>
            [ { '_id' => 1, '_score' => 0.5, '_index' => 'testing', '_type' => 'article',
                'fields' => {
                  'title'       => 'Knee Deep in JSON',
                  'crazy.field' => 'CRAAAAZY!',
                  '_source.artist' => {
                    'name' => 'Elastiq',
                    'meta' => {
                      'favorited' => 1000,
                      'url'       => 'http://first.fm/abc123/xyz567'
                    }
                  },
                  '_source.track.info.duration' => {
                    'minutes' => 3
                  }
                } } ] } }
          collection = Results::Collection.new(@default_response)
          @item      = collection.first
        end

        should "return fields from the first level" do
          assert_equal 'Knee Deep in JSON', @item.title
        end

        should "return fields from the _source prefixed and nested fields" do
          assert_equal 'Elastiq', @item.artist.name
          assert_equal 1000,      @item.artist.meta.favorited
          assert_equal 3,         @item.track.info.duration.minutes
        end

      end

      context "using fields when also returning the _source" do
        setup do
          Configuration.reset
          @default_response = { 'hits' => { 'hits' =>
            [ { '_id' => 1, '_score' => 0.5, '_index' => 'testing', '_type' => 'article',
                '_source' => {
                  'title' => 'Knee Deep in JSON'
                },
                'fields' => {
                  '_parent' => '4f99f98ea2b279ec3d002522'
                }
              }
            ] } }
          collection = Results::Collection.new(@default_response)
          @item      = collection.first
        end

        should "return an individual field" do
          assert_equal '4f99f98ea2b279ec3d002522', @item._parent
        end

        should "return fields from the _source as well" do
          assert_equal 'Knee Deep in JSON', @item.title
        end
      end

      context "returning results with hits" do
        should "yield the Item result and the raw hit" do
          response = { 'hits' => { 'hits' => [ { '_id' => 1, '_score' => 0.5, '_index' => 'testing', '_type' => 'article', '_source' => { :title => 'Test', :body => 'Lorem' } } ] } }

          Results::Collection.new(response).each_with_hit do |result, hit|
            assert_instance_of Tire::Results::Item, result
            assert_instance_of Hash, hit
            assert_equal 'Test',   result.title
            assert_equal 0.5, hit['_score']
          end
        end

        should "yield the model instance and the raw hit" do
          response = { 'hits' => { 'hits' => [ {'_id' => 1, '_score' => 0.5, '_type' => 'active_record_article'} ] } }

          ActiveRecord::Base.establish_connection( :adapter => 'sqlite3', :database => ":memory:" )
          ActiveRecord::Migration.verbose = false
          ActiveRecord::Schema.define(:version => 1) { create_table(:active_record_articles) { |t| t.string(:title) } }
          model = ActiveRecordArticle.new(:title => 'Test'); model.id = 1

          ActiveRecordArticle.expects(:find).with([1]).returns([ model] )

          Results::Collection.new(response, :load => true).each_with_hit do |result, hit|
            assert_instance_of ActiveRecordArticle, result
            assert_instance_of Hash, hit
            assert_equal 'Test',   result.title
            assert_equal 0.5, hit['_score']
          end

        end


      end

      context "while paginating results" do

        setup do
          @default_response = { 'hits' => { 'hits' => [{'_id' => 1, '_score' => 1, '_source' => {:title => 'Test'}},
                                                       {'_id' => 2},
                                                       {'_id' => 3},
                                                       {'_id' => 4}],
                                            'total' => 4 },
                                'took' => 1 }
          @collection = Results::Collection.new( @default_response, :per_page => 1, :page => 2 )
        end

        should "return total entries" do
          assert_equal 4, @collection.total
          assert_equal 4, @collection.total_entries
        end

        should "return total pages" do
          assert_equal 4, @collection.total_pages
          @collection = Results::Collection.new( @default_response, :per_page => 2, :page => 2 )
          assert_equal 2, @collection.total_pages
          @collection = Results::Collection.new( @default_response, :per_page => 3, :page => 2 )
          assert_equal 2, @collection.total_pages
        end

        should "return total pages when per_page option not set" do
          collection = Results::Collection.new( @default_response, :page => 1 )
          assert_equal 1, collection.total_pages
        end

        should "return current page" do
          assert_equal 2, @collection.current_page
        end

        should "return current page for empty result" do
          collection = Results::Collection.new( { 'hits' => { 'hits' => [], 'total' => 0 } } )
          assert_equal 1, collection.current_page
        end

        should "return previous page" do
          assert_equal 1, @collection.previous_page
        end

        should "return next page" do
          assert_equal 3, @collection.next_page
        end

        should "have default per_page" do
          assert_equal 10, Tire::Results::Pagination::default_per_page

          collection = Results::Collection.new @default_response
          assert_equal 10, collection.per_page
        end

      end

      context "with eager loading" do
        setup do
          @response = { 'hits' => { 'hits' => [ {'_id' => 1, '_type' => 'active_record_article'},
                                                {'_id' => 2, '_type' => 'active_record_article'},
                                                {'_id' => 3, '_type' => 'active_record_article'}] } }
          ActiveRecordArticle.stubs(:inspect).returns("<ActiveRecordArticle>")
        end

        should "load the records via model find method from database" do
          ActiveRecordArticle.expects(:find).with([1,2,3]).
                              returns([ Results::Item.new(:id => 3),
                                        Results::Item.new(:id => 1),
                                        Results::Item.new(:id => 2)  ])
          Results::Collection.new(@response, :load => true).results
        end

        should "pass the :load option Hash to model find metod" do
          ActiveRecordArticle.expects(:find).with([1,2,3], :include => 'comments').
                              returns([ Results::Item.new(:id => 3),
                                        Results::Item.new(:id => 1),
                                        Results::Item.new(:id => 2)  ])
          Results::Collection.new(@response, :load => { :include => 'comments' }).results
        end

        should "preserve the order of records returned from search" do
          ActiveRecordArticle.expects(:find).with([1,2,3]).
                              returns([ Results::Item.new(:id => 3),
                                        Results::Item.new(:id => 1),
                                        Results::Item.new(:id => 2)  ])
          assert_equal [1,2,3], Results::Collection.new(@response, :load => true).results.map(&:id)
        end

        should "raise error when model class cannot be inferred from _type" do
          assert_raise(NameError) do
            response = { 'hits' => { 'hits' => [ {'_id' => 1, '_type' => 'hic_sunt_leones'}] } }
            Results::Collection.new(response, :load => true).results
          end
        end

        should "raise error when _type is missing" do
          assert_raise(NoMethodError) do
            response = { 'hits' => { 'hits' => [ {'_id' => 1}] } }
            Results::Collection.new(response, :load => true).results
          end
        end

        should "return empty array for empty hits" do
          response = { 'hits'  => {
                         'hits' => [],
                         'total' => 4
                       },
                       'took'  => 1 }
          @collection = Results::Collection.new( response, :load => true )
          assert @collection.empty?, 'Collection should be empty'
          assert @collection.results.empty?, 'Collection results should be empty'
          assert_equal 0, @collection.size
        end
      end

      context "with ActiveModel::Serializers" do
        setup do
          require 'active_model_serializers'

          Tire::Results::Collection.send :include, ActiveModel::ArraySerializerSupport

          class ::MyItemWithSerializer < Tire::Results::Item
            include ActiveModel::SerializerSupport

            def active_model_serializer
              ::MyItemSerializer
            end
          end

          class ::MyItemSerializer < ActiveModel::Serializer
            attribute :title,  :key => :name
            attribute :author, :key => :owner
          end
        end

        should "be serializable" do
          assert_nothing_raised do
            collection = Results::Collection.new(@default_response, :wrapper => ::MyItemWithSerializer)
            serializer = collection.active_model_serializer.new(collection)

            hash = serializer.as_json.first
            assert_equal 'Test',    hash[:name]
            assert_equal 'John', hash[:owner]
          end
        end
      end

    end

  end

end
