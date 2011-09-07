require 'test_helper'

module Tire

  class ConfigurationTest < Test::Unit::TestCase

    def teardown
      Tire::Configuration.reset
    end

    context "Configuration" do
      setup do
        Configuration.instance_variable_set(:@url,    nil)
        Configuration.instance_variable_set(:@client, nil)
        Configuration.instance_variable_set(:@index_prefix, nil)
      end

      teardown do
        Configuration.reset
      end

      should "return default URL" do
        assert_equal 'http://localhost:9200', Configuration.url
      end

      should "allow setting and retrieving the URL" do
        assert_nothing_raised { Configuration.url 'http://example.com' }
        assert_equal 'http://example.com', Configuration.url
      end

      should "strip trailing slash from the URL" do
        assert_nothing_raised { Configuration.url 'http://slash.com:9200/' }
        assert_equal 'http://slash.com:9200', Configuration.url
      end

      should "return default client" do
        assert_equal Client::RestClient, Configuration.client
      end

      should "return nil as logger by default" do
        assert_nil Configuration.logger
      end

      should "return set and return logger" do
        Configuration.logger STDERR
        assert_not_nil Configuration.logger
        assert_instance_of Tire::Logger, Configuration.logger
      end

      should "return default nil index prefix" do
        assert_nil Configuration.index_prefix
      end

      should "allow setting and retrieving the index prefix" do
        assert_nothing_raised { Configuration.index_prefix 'app_environment_' }
        assert_equal 'app_environment_', Configuration.index_prefix
      end

      should "allow to reset the configuration for specific property, and does not affect others" do
        Configuration.url 'http://example.com'
        Configuration.index_prefix 'app_environment_'
        assert_equal      'http://example.com', Configuration.url
        assert_equal      'app_environment_', Configuration.index_prefix
        Configuration.reset :url
        assert_equal      'http://localhost:9200', Configuration.url
        assert_equal      'app_environment_', Configuration.index_prefix
      end

      should "allow to reset the configuration for all properties" do
        Configuration.url     'http://example.com'
        Configuration.index_prefix 'app_environment_'
        Configuration.wrapper Hash
        assert_equal          'http://example.com', Configuration.url
        assert_equal          'app_environment_', Configuration.index_prefix
        Configuration.reset
        assert_equal          'http://localhost:9200', Configuration.url
        assert_equal          Client::RestClient, Configuration.client
        assert_nil Configuration.index_prefix
        
      end
    end

  end

end
