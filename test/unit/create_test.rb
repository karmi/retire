require 'test_helper'

module Tire

  class CreateTest < Test::Unit::TestCase

    context "Create" do

      setup do
        @index = Tire::Index.new 'dummy'
      end

      should "bulk store should accept method argument" do
        Configuration.client.expects(:post).with do |url, json|
          url  == "#{Configuration.url}/_bulk" &&
          json =~ /\A{"create":.*?}}/
        end.returns(mock_response('{}'), 200)

        @index.bulk_store [ {:id => '1', :title => 'One'}, {:id => '2', :title => 'Two'} ], method: 'create'
      end
    end
  end
end
