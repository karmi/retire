require 'test_helper'

module Tire

  class RubyCoreExtensionsTest < Test::Unit::TestCase

    context "Hash" do

      context "with no to_json method provided" do

        setup do
          @hash = { :one => 1}
          # Undefine the `to_json` method...
          ::Hash.class_eval { remove_method(:to_json) rescue nil }
          # ... and reload the extension, so it's added
          load 'tire/rubyext/hash.rb'
        end

        should "have its own to_json method" do
          assert_respond_to( @hash, :to_json )
          assert_equal '{"one":1}', @hash.to_json
        end

        should "allow to pass options to to_json for compatibility" do
          assert_nothing_raised do
            assert_equal '{"one":1}', @hash.to_json({})
          end
        end

      end

      should "have a to_json method from a JSON serialization library" do
        assert_respond_to( {}, :to_json )
        assert_equal '{"one":1}', { :one => 1}.to_json
      end

      should "have to_indexed_json method doing the same as to_json" do
        [{}, { :foo => 2 }, { :foo => 4, :bar => 6 }, { :foo => [7,8,9] }].each do |h|
          assert_equal MultiJson.decode(h.to_json), MultiJson.decode(h.to_indexed_json)
        end
      end

      should "properly serialize Time into JSON" do
        json = { :time => Time.mktime(2011, 01, 01, 11, 00).to_json  }.to_json
        assert_match /"2011-01-01T11:00:00.*"/, MultiJson.decode(json)['time']
      end

    end

    context "Array" do

      should "encode itself to JSON" do
        assert_equal '["one","two"]', ['one','two'].to_json
      end

    end

    context "Ruby Test::Unit" do
      should "actually return true from assert..." do
        assert_equal true, assert(true)
      end
    end

  end

end
