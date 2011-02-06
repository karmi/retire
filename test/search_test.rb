require 'test_helper'

module Slingshot::Search

  class SearchTest < Test::Unit::TestCase

    context "Search" do

      should "be initialized with indices and a block" do
        assert_raise(ArgumentError) { Search.new }
        assert_raise(ArgumentError) { Search.new 'index' }
      end

      should "have the query method" do
        q = ( Search.new('index') do;end ).query do;end
        assert_kind_of(Query, q)
      end

      should "store indices as an array" do
        s = Search.new('index1') do;end
        assert_equal ['index1'], s.indices

        s = Search.new('index1', 'index2') do;end
        assert_equal ['index1', 'index2'], s.indices
      end

    end

  end

end
