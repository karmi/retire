require 'test_helper'

module Tire

  class DslIndicesIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "When calling the indices method" do

      setup do
        # it generates random strings of lowercase a-z and 0-9 of lenght 8
        @index_name = rand(36**8).to_s(36)
        @index = Tire.index @index_name do
          delete
          create
        end

      end

      teardown { Tire.index(@index_name).delete }

      should "include the created index in index list" do
        assert_include Tire.indices, @index_name
      end

    end
  end

end
