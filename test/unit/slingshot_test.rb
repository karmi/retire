require 'test_helper'

module Slingshot

  class SlingshotTest < Test::Unit::TestCase

    context "Slingshot" do

      should "have the DSL methods available" do
        assert_respond_to Slingshot, :search
        assert_respond_to Slingshot, :index
      end
    end

  end

end
