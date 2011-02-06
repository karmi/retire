require 'test_helper'

module Slingshot

  class ResultsCollectionTest < Test::Unit::TestCase

    context "Collection" do
      setup do
        @default_response = { 'hits' => { 'hits' => [1, 2, 3] } }
      end

      should "be iterable" do
        assert_respond_to Results::Collection.new(@default_response), :each
      end

      should "be initialized with parsed json" do
        assert_nothing_raised do
          collection = Results::Collection.new( @default_response )
          assert_equal [1,2,3], collection.results
        end
      end

    end

  end

end
