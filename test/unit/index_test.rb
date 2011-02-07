require 'test_helper'

module Slingshot

  class IndexTest < Test::Unit::TestCase

    context "Index" do

      setup do
        @index = Slingshot::Index.new 'dummy'
      end

      should "create new index" do
        Configuration.client.expects(:post).returns('{"ok":true,"acknowledged":true}')
        assert @index.create
      end

      should "not raise exception and just return false when trying to create existing index" do
        Configuration.client.expects(:post).raises(RestClient::BadRequest)
        assert_nothing_raised { assert ! @index.create }
      end

      should "delete index" do
        Configuration.client.expects(:delete).returns('{"ok":true,"acknowledged":true}')
        assert @index.delete
      end

      should "not raise exception and just return false when deleting non-existing index" do
        Configuration.client.expects(:delete).returns('{"error":"[articles] missing"}')
        assert_nothing_raised { assert ! @index.delete }
        Configuration.client.expects(:delete).raises(RestClient::BadRequest)
        assert_nothing_raised { assert ! @index.delete }
      end

      should "refresh the index" do
        Configuration.client.expects(:post).returns('{"ok":true,"_shards":{}}')
        assert_nothing_raised { assert @index.refresh }
      end

    end

  end

end
