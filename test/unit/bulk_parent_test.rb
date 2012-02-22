require 'test_helper'

module Tire

  class CreateTest < Test::Unit::TestCase

    context "Bulk Parent" do

      setup do
        @index = Tire::Index.new 'dummy'
        Tire.index 'dummy' do
          create :mappings => {
            :blog => {
              :properties => {
                :text => "string"
              }
            },
            :blog_tag => {
                :_parent => {
                  :type => "blog"
                }
              }
            }
        end
      end

      should "bulk store should handle the '_parent' field" do
        Configuration.client.expects(:post).with do |url, json|
          url  == "#{Configuration.url}/_bulk" &&
          json =~ /\A{.*?"_parent":"abcdef".*?}}/
        end.returns(mock_response('{}'), 200)

        @index.bulk_store [ {:id => '1', :title => 'One', :_parent => "abcdef", :type => "blog_tag"}, {:id => '2', :title => 'Two', :type => "blog_tag", :_parent => "qwerty"} ]
      end

      should "bulk store should handle the 'parent' field" do
        Configuration.client.expects(:post).with do |url, json|
          url  == "#{Configuration.url}/_bulk" &&
            json =~ /\A{.*?"_parent":"abcdef".*?}}/
        end.returns(mock_response('{}'), 200)

          @index.bulk_store [ {:id => '1', :title => 'One', :parent => "abcdef", :type => "blog_tag"}, {:id => '2', :title => 'Two', :type => "blog_tag", :parent => "qwerty"} ]
      end
    end
  end
end

