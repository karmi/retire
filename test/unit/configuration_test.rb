require 'test_helper'

module Slingshot

  class ConfigurationTest < Test::Unit::TestCase

    context "Configuration" do
      setup do
        Configuration.url    = nil
        Configuration.client = nil
      end

      should "return default URL" do
        assert_equal 'http://localhost:9200', Configuration.url
      end

      should "allow setting and retrieving the URL" do
        assert_nothing_raised { Configuration.url = 'http://example.com' }
        assert_equal 'http://example.com', Configuration.url
      end

      should "return default client" do
        assert_equal Client::RestClient, Configuration.client
      end

      should "allow setting and retrieving the client" do
        assert_nothing_raised { Configuration.client = Client::Base }
        assert_equal Client::Base, Configuration.client
      end
    end

  end

end
