require 'test_helper'

module Slingshot::Search

  class FacetTest < Test::Unit::TestCase

    context "Facet" do

      should "be serialized to JSON" do
        assert_respond_to Facet.new('foo'), :to_json
      end

      context "generally" do

        should "encode facets with defaults for current query" do
          assert_equal( { :foo => { :terms => {:field=>'bar',:size=>10,:all_terms=>false} } }.to_json,
                        Facet.new('foo').terms(:bar).to_json )
        end

        should "encode facets as global" do
          assert_equal( { :foo => { :terms => {:field=>'bar',:size=>10,:all_terms=>false}, :global => true } }.to_json,
                        Facet.new('foo', :global => true).terms(:bar).to_json )
        end

        should "encode facet options" do
          assert_equal( { :foo => { :terms => {:field=>'bar',:size=>5,:all_terms=>false} } }.to_json,
                        Facet.new('foo').terms(:bar, 5).to_json )
        end

        should "encode facets when passed as a block" do
          f = Facet.new('foo') do
            terms :bar
          end
          assert_equal( { :foo => { :terms => {:field=>'bar',:size=>10,:all_terms=>false} } }.to_json, f.to_json )
        end

      end

      context "terms facet" do

        should "encode the default all_terms option" do
          assert_equal false, Facet.new('foo') { terms :foo }.to_hash['foo'][:terms][:all_terms]
        end

        should "encode the all_terms option" do
          assert_equal true, Facet.new('foo') { terms :foo, 10, true }.to_hash['foo'][:terms][:all_terms]
        end

      end

      context "date histogram" do

        should "encode the JSON" do
          f = Facet.new('date') { date :published_on, 'day' }
          assert_equal({ :date => { :date_histogram => { :field => 'published_on', :interval => 'day' } } }.to_json, f.to_json)
        end

      end

    end

  end

end
