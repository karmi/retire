require 'test_helper'

module Slingshot

  class ResultsCollectionTest < Test::Unit::TestCase

    context "Collection" do
      setup do
        Configuration.reset :wrapper
        @default_response = { 'hits' => { 'hits' => [{:_id => 1}, {:_id => 2}, {:_id => 3}] } }
      end

      should "be iterable" do
        assert_respond_to Results::Collection.new(@default_response), :each
        assert_nothing_raised do
          Results::Collection.new(@default_response).each { |item| item[:_id] + 1 }
          Results::Collection.new(@default_response).map  { |item| item[:_id] + 1 }
        end
      end

      should "be initialized with parsed json" do
        assert_nothing_raised do
          collection = Results::Collection.new( @default_response )
          assert_equal 3, collection.results.count
        end
      end

      context "wrapping results" do

        setup do
          @response = { 'hits' => { 'hits' => [ { '_id' => 1, '_source' => { :title => 'Test', :body => 'Lorem' } } ] } }
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

        should "delegate results to wrapper find method for :searchable wrappers" do
          class FakeModel
            def self.find(*args); end
            def self.mode; :searchable; end
          end
          Configuration.wrapper FakeModel
          FakeModel.expects(:find).with([1])

          Results::Collection.new(@response)
        end

      end

    end

  end

end
