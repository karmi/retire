require 'test_helper'

module Tire

  class RubyCoreExtensionsTest < Test::Unit::TestCase

    context "Hash" do

      should "have to_json method" do
        assert_respond_to( {}, :to_json )
        assert_equal '{"one":1}', { :one => 1}.to_json
      end

      should "have to_indexed_json method doing the same as to_json" do
        [{}, { 1 => 2 }, { 3 => 4, 5 => 6 }, { nil => [7,8,9] }].each do |h|
          assert_equal MultiJson.decode(h.to_json), MultiJson.decode(h.to_indexed_json)
        end
      end

    end

  end

end
