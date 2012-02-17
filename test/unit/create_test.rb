require 'test_helper'

module Tire

  class CreateTest < Test::Unit::TestCase

    context "Create" do

      setup do
        @index = Tire::Index.new 'dummy'
      end

      should "have a name" do
        Configuration.client.expects(:post).with do |url, json|
          url  == "#{Configuration.url}/_bulk" &&
          json =~ /\A{"create": .*}}\Z/
        end.returns(mock_response('{}'), 200)

        @index.bulk_store [ {:id => '1', :title => 'One'}, {:id => '2', :title => 'Two'} ], method: 'create'
      end
    end
  end
end
