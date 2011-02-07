require 'test_helper'

module Slingshot::Search

  class FacetsTest < Test::Unit::TestCase

    context "Facets" do

      should "be serialized to JSON" do
        assert_respond_to Sort.new, :to_json
      end

      context "generally" do

        should "encode facets with defaults for current query" do
          assert_equal( { :foo => { :terms => {:field=>'bar'} } }.to_json, Facets.new('foo').terms(:bar).to_json )
        end

        should "encode facets as global" do
          assert_equal( { :foo => { :terms => {:field=>'bar'}, :global =>true } }.to_json,
                        Facets.new('foo').terms(:bar, :global => true).to_json )
        end

        should "encode facets when passed as a block" do
          f = Facets.new('foo') do
            terms :bar
          end
          assert_equal( { :foo => { :terms => {:field=>'bar'} } }.to_json, f.to_json )
        end

      end

    end

  end

end
