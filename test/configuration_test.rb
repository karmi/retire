require 'test_helper'

module Slingshot

  class ConfigurationTest < Test::Unit::TestCase

    context "Configuration" do
      setup { Configuration.url = nil }

      should "return default URL" do
        assert_equal 'http://localhost:9200', Configuration.url
      end

      should "allow setting and retrieving the URL" do
        assert_nothing_raised { Configuration.url = 'http://example.com' }
        assert_equal 'http://example.com', Configuration.url
      end
    end

  end

end
