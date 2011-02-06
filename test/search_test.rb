require 'test_helper'

module Slingshot::Search

  class SearchTest < Test::Unit::TestCase

    context "Search" do

      should "be initialized with indices and a block" do
        assert_raise(ArgumentError) { Search.new }
        assert_raise(ArgumentError) { Search.new 'index' }
      end

    end

  end

end
