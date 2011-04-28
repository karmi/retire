require 'test_helper'

module Slingshot

  class RubyextHashTest < Test::Unit::TestCase

    context "Hash" do

      should "have to_indexed_json doing the same as to_json" do
        [{}, { 1 => 2 }, { 3 => 4, 5 => 6 }, { nil => [7,8,9] }].each do |h|
          assert_equal h.to_json, h.to_indexed_json
        end
      end

    end

  end

end
