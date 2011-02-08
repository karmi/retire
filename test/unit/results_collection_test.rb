require 'test_helper'

module Slingshot

  class ResultsCollectionTest < Test::Unit::TestCase

    context "Collection" do
      setup do
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

        should "wrap hits in Item" do
          response = { 'hits' => { 'hits' => [ { '_id' => 1, '_source' => { :title => 'Test', :body => 'Lorem' } } ] } }
          document =  Results::Collection.new(response).first
          assert_kind_of Results::Item, document
          assert_equal 'Test', document.title
        end

        should "allow access to raw underlying Hash" do
          response = { 'hits' => { 'hits' => [ { '_id' => 1, '_source' => { :title => 'Test', :body => 'Lorem' } } ] } }
          document = Results::Collection.new(response).first
          assert_not_nil document[:_source][:title]
          assert_equal 'Test', document[:_source][:title]
        end

      end

    end

  end

end
