require 'test_helper'

module Slingshot

  class RubyCoreExtensionsTest < Test::Unit::TestCase

    context "Hash" do

      should "have to_indexed_json doing the same as to_json" do
        [{}, { 1 => 2 }, { 3 => 4, 5 => 6 }, { nil => [7,8,9] }].each do |h|
          assert_equal Yajl::Parser.parse(h.to_json), Yajl::Parser.parse(h.to_indexed_json)
        end
      end

    end

  end

end
