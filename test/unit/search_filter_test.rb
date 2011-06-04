require 'test_helper'

module Tire::Search

  class FilterTest < Test::Unit::TestCase

    context "Filter" do

      should "be serialized to JSON" do
        assert_respond_to Filter.new(:terms, {}), :to_json
      end

      should "encode simple filter declarations as JSON" do
        assert_equal( { :terms => {} }.to_json,
                      Filter.new('terms').to_json )

        assert_equal( { :terms => { :tags => ['foo'] } }.to_json,
                      Filter.new('terms', :tags => ['foo']).to_json )

        assert_equal( { :range => { :age => { :from => 10, :to => 20 } } }.to_json,
                      Filter.new('range', { :age => { :from => 10, :to => 20 } }).to_json )

        assert_equal( { :geo_distance => { :distance => '12km', :location => [40, -70] } }.to_json,
                      Filter.new('geo_distance', { :distance => '12km', :location => [40, -70] }).to_json )
      end

      should "encode 'or' filter with multiple other filters" do
        # See http://www.elasticsearch.org/guide/reference/query-dsl/or-filter.html
        assert_equal( { :or => [ {:terms => {:tags => ['foo']}}, {:terms => {:tags => ['bar']}} ] }.to_json,
                      Filter.new('or', {:terms => {:tags => ['foo']}}, {:terms => {:tags => ['bar']}}).to_json )
      end

      should "encode 'bool' filter with multiple filters" do
        # http://www.elasticsearch.org/guide/reference/query-dsl/bool-filter.html
        assert_equal( { :bool => [ {:must => {:terms => {:tags => ['foo']}}}, {:should => {:terms => {:tags => ['bar']}}} ] }.to_json,
                      Filter.new('bool', {:must => {:terms => {:tags => ['foo']}}}, { :should => {:terms => {:tags => ['bar']}}}).to_json )
      end

    end

  end
end
