require 'test_helper'

module Tire::Search

  class SortTest < Test::Unit::TestCase

    context "Sort" do

      should "be serialized to JSON" do
        assert_respond_to Sort.new, :to_json
      end

      should "encode simple strings" do
        assert_equal [:foo].to_json, Sort.new.by(:foo).to_json
      end

      should "encode method arguments" do
        assert_equal [:foo => 'desc'].to_json, Sort.new.by(:foo, 'desc').to_json
      end

      should "encode hash" do
        assert_equal [ :foo => { :reverse => true } ].to_json, Sort.new.by(:foo, :reverse => true).to_json
      end

      should "encode multiple sort fields in chain" do
        assert_equal [:foo, :bar].to_json, Sort.new.by(:foo).by(:bar).to_json
      end

      should "encode fields when passed as a block to constructor" do
        s = Sort.new do
          by :foo
          by :bar, 'desc'
          by :_score
        end
        assert_equal [ :foo, {:bar => 'desc'}, :_score ].to_json, s.to_json
      end

      should "encode fields deeper in json" do
        s = Sort.new { by 'author.name' }
        assert_equal [ 'author.name' ].to_json, s.to_json

        s = Sort.new { by 'author.name', 'desc' }
        assert_equal [ {'author.name' => 'desc'} ].to_json, s.to_json
      end

    end

  end

end
