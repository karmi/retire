require 'test_helper'

module Tire

  class CreateTest < Test::Unit::TestCase

    context "Create" do

      setup do
        @index = Tire::Index.new 'dummy'
      end

      should "bulk store should not be dependent on the presence of an _id parameter" do
        Configuration.client.expects(:post).with do |url, json|
          url  == "#{Configuration.url}/_bulk" &&
          json !~ /_id/
        end.returns(mock_response('{}'), 200)

        @index.bulk_store [ {:title => 'One'}, {:title => 'Two'} ]
      end
    end
  end
end

