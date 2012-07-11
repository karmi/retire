require 'test_helper'

module Tire::Search

  class ScriptFieldTest < Test::Unit::TestCase

    context "ScriptField" do

      should "be serialized to JSON" do
        assert_respond_to ScriptField.new(:test1, {}), :to_json
      end

      should "encode simple declarations as JSON" do
        assert_equal( { :test1 => { :script => "doc['my_field_name'].value * factor",
                                    :params => { :factor => 2.2 }, :lang => :js } }.to_json,

                      ScriptField.new(   :test1,
                                       { :script => "doc['my_field_name'].value * factor",
                                         :params => { :factor => 2.2 }, :lang => :js }      ).to_json
                    )
      end

    end

  end
end
