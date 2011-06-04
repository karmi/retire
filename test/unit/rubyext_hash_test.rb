require 'test_helper'

module Tire

  class RubyCoreExtensionsTest < Test::Unit::TestCase

    context "Hash" do

      context "with no to_json method provided" do
        setup do
          @hash = { :one => 1}
          # Undefine the `to_json` method...
          class Hash; undef_method(:to_json); end
          # ... and reload the extension, so it's added
          load 'tire/rubyext/hash.rb'
        end

        should "have its own to_json method" do
          assert_respond_to( @hash, :to_json )
          assert_equal '{"one":1}', @hash.to_json
        end

      end

      should "have a to_json method from Yajl" do
        assert defined?(Yajl)
        assert_respond_to( {}, :to_json )
        assert_equal '{"one":1}', { :one => 1}.to_json
      end

      should "have to_indexed_json method doing the same as to_json" do
        [{}, { 1 => 2 }, { 3 => 4, 5 => 6 }, { nil => [7,8,9] }].each do |h|
          assert_equal MultiJson.decode(h.to_json), MultiJson.decode(h.to_indexed_json)
        end
      end

      should "properly serialize Time into JSON" do
        json = { :time => Time.mktime(2011, 01, 01, 11, 00).to_json  }.to_json
        assert_equal '"2011-01-01T11:00:00+01:00"', MultiJson.decode(json)['time']
      end

    end

  end

end
