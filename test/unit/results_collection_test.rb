require 'test_helper'

module Slingshot

  class ResultsCollectionTest < Test::Unit::TestCase

    context "Collection" do
      setup do
        Configuration.reset :wrapper
        @default_response = { 'hits' => { 'hits' => [{:_id => 1, :_score => 1, :_source => {:title => 'Test'}},
                                                     {:_id => 2},
                                                     {:_id => 3}] } }
      end

      should "be iterable" do
        assert_respond_to Results::Collection.new(@default_response), :each
        assert_respond_to Results::Collection.new(@default_response), :size
        assert_nothing_raised do
          Results::Collection.new(@default_response).each { |item| item[:_id] + 1 }
          Results::Collection.new(@default_response).map  { |item| item[:_id] + 1 }
        end
      end

      should "have size" do
        assert_equal 3, Results::Collection.new(@default_response).size
      end

      should "be initialized with parsed json" do
        assert_nothing_raised do
          collection = Results::Collection.new( @default_response )
          assert_equal 3, collection.results.count
        end
      end

      should "store passed options" do
        collection = Results::Collection.new( @default_response, :per_page => 20, :page => 2 )
        assert_equal 20, collection.options[:per_page]
        assert_equal 2,  collection.options[:page]
      end

      context "wrapping results" do

        setup do
          @response = { 'hits' => { 'hits' => [ { '_id' => 1, '_score' => 0.5, '_source' => { :title => 'Test', :body => 'Lorem' } } ] } }
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

      end

      context "while paginating results" do

        setup do
          @default_response = { 'hits' => { 'hits' => [{:_id => 1, :_score => 1, :_source => {:title => 'Test'}},
                                                       {:_id => 2},
                                                       {:_id => 3}],
                                            'total' => 3,
                                            'took'  => 1 } }
          @collection = Results::Collection.new( @default_response, :per_page => 1, :page => 2 )
        end

        should "return total entries" do
          assert_equal 3, @collection.total
          assert_equal 3, @collection.total_entries
        end

        should "return total pages" do
          assert_equal 3, @collection.total_pages
        end

        should "return total pages when per_page option not set" do
          collection = Results::Collection.new( @default_response, :page => 1 )
          assert_equal 1, collection.total_pages
        end

        should "return current page" do
          assert_equal 2, @collection.current_page
        end

        should "return previous page" do
          assert_equal 1, @collection.previous_page
        end

        should "return next page" do
          assert_equal 3, @collection.next_page
        end

      end

    end

  end

end
