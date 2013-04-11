require 'test_helper'

module Tire::Search

  class FacetTest < Test::Unit::TestCase

    context "Facet" do

      should "be serialized to JSON" do
        assert_respond_to Facet.new('foo'), :to_json
      end

      context "generally" do

        should "encode facets with defaults for current query" do
          assert_equal( MultiJson.load({ :foo => { :terms => {:field=>'bar',:size=>10,:all_terms=>false} } }.to_json),
                        MultiJson.load(Facet.new('foo').terms(:bar).to_json) )
        end

        should "encode facets as global" do
          assert_equal( MultiJson.load({ :foo => { :terms => {:field=>'bar',:size=>10,:all_terms=>false}, :global => true } }.to_json),
                        MultiJson.load(Facet.new('foo', :global => true).terms(:bar).to_json) )
        end

        should "pass options to facets" do
          payload = Facet.new('foo', :facet_filter => { :term => { :account_id => 'foo' } }).terms(:bar).to_hash

          assert_not_nil payload['foo'][:facet_filter]
          assert_equal( { :term => { :account_id => 'foo' } },
                        payload['foo'][:facet_filter] )
        end

        should "encode facet options" do
          assert_equal( MultiJson.load( { :foo => { :terms => {:field=>'bar',:size=>5,:all_terms=>false} } }.to_json ),
                        MultiJson.load( Facet.new('foo').terms(:bar, :size => 5).to_json ) )
        end

        should "encode facets when passed as a block" do
          f = Facet.new('foo') do
            terms :bar
          end
          assert_equal( MultiJson.load({ :foo => { :terms => {:field=>'bar',:size=>10,:all_terms=>false} } }.to_json),
                        MultiJson.load(f.to_json) )
        end

        should "encode facets when passed as a block, using variables from outer scope" do
          def foo; 'bar'; end

          f = Facet.new('foo') do |facet|
            facet.terms foo, :size => 20
          end
          assert_equal( MultiJson.load({ :foo => { :terms => {:field=>'bar',:size=>20,:all_terms=>false} } }.to_json),
                        MultiJson.load(f.to_json) )
        end

        should "encode facet_filter option with DSL" do
          f = Facet.new('foo'){
            terms :published_on
            facet_filter :terms, :tags => ['ruby']
          }.to_hash

          assert_equal( { :terms => {:tags => ['ruby'] }}.to_json, f['foo'][:facet_filter].to_json)
        end

        should "encode multiple facet_filter options with DSL" do
          f = Facet.new('foo'){
            terms :published_on
            facet_filter :and, { :tags => ['ruby'] },
                               { :words => 250 }
          }.to_hash

          assert_equal( { :and => [{:tags => ['ruby']}, {:words => 250 }] }.to_json,
                        f['foo'][:facet_filter].to_json )
        end

        should "allow arbitrary ordering of methods in the DSL block" do
          f = Facet.new('foo') do
            facet_filter :terms, :tags => ['ruby']
            terms :published_on
          end.to_hash

          assert_equal( { :terms => {:tags => ['ruby'] }}.to_json, f['foo'][:facet_filter].to_json)
        end

      end

      context "terms facet" do

        should "encode the default all_terms option" do
          assert_equal false, Facet.new('foo') { terms :foo }.to_hash['foo'][:terms][:all_terms]
        end

        should "encode the all_terms option" do
          assert_equal true, Facet.new('foo') { terms :foo, :all_terms => true }.to_hash['foo'][:terms][:all_terms]
        end

        should "encode custom options" do
          assert_equal( MultiJson.load({ :foo => { :terms => {:field=>'bar',:size=>5,:all_terms=>false,:exclude=>['moo']} } }.to_json),
                        MultiJson.load(Facet.new('foo').terms(:bar, :size => 5, :exclude => ['moo']).to_json) )
        end

      end

      context "date histogram" do

        should "encode the JSON with default values" do
          f = Facet.new('date') { date :published_on }
          assert_equal({ :date => { :date_histogram => { :field => 'published_on', :interval => 'day' } } }.to_json, f.to_json)
        end

        should "encode the JSON with custom interval" do
          f = Facet.new('date') { date :published_on, :interval => 'month' }
          assert_equal({ :date => { :date_histogram => { :field => 'published_on', :interval => 'month' } } }.to_json, f.to_json)
        end

        should "encode custom options" do
          f = Facet.new('date') { date :published_on, :value_field => 'price'  }
          assert_equal( {:date=>{:date_histogram=>{:key_field=>'published_on',:interval=>'day',:value_field=>'price' } } }.to_json,
                        f.to_json )
        end

      end

      context "range facet" do
        should "encode facet options" do
          f = Facet.new('range') { range :published_on, [{:to => '2010-12-31'}, {:from => '2011-01-01', :to => '2011-05-27'}, {:from => '2011-05-28'}]}
          assert_equal({ :range => { :range => { :field => 'published_on', :ranges => [{:to => '2010-12-31'}, {:from => '2011-01-01', :to => '2011-05-27'}, {:from => '2011-05-28'}] } } }.to_json, f.to_json)
        end
      end

      context "histogram facet" do
        should "encode facet options with default key" do
          f = Facet.new('histogram') { histogram :age, {:interval => 5} }
          assert_equal({ :histogram => { :histogram => { :field => 'age', :interval => 5 } } }.to_json, f.to_json)
        end

        should "encode the JSON if define an histogram" do
          f = Facet.new('histogram') { histogram :age, {:histogram => {:key_field => "age", :value_field => "age", :interval => 100}} }
          assert_equal({ :histogram => { :histogram => {:key_field => "age", :value_field => "age", :interval => 100} } }.to_json, f.to_json)
        end
      end

      context "statistical facet" do
        should "encode facet options" do
          f = Facet.new('statistical') { statistical :words }
          assert_equal({:statistical => {:statistical => {:field => 'words'}}}.to_json, f.to_json)
        end

        should "encode the JSON if a 'statistical' custom option is defined" do
          f = Facet.new('statistical') { statistical :words, :statistical => {:params => {:factor => 5}} }
          assert_equal({:statistical => {:statistical => {:params => {:factor => 5 }}}}.to_json, f.to_json)
        end
      end

      context "terms_stats facet" do
        should "should encode facet options" do
          f = Facet.new('terms_stats') { terms_stats :tags, :words }
          assert_equal({:terms_stats => {:terms_stats => {:key_field => 'tags', :value_field => 'words'}}}.to_json, f.to_json)
        end
      end

      context "query facet" do
        should "encode facet options" do
          f = Facet.new('q_facet') do
            query { string '_exists_:foo' }
          end
          assert_equal({ :q_facet => { :query => { :query_string => { :query => '_exists_:foo' } } } }.to_json, f.to_json)
        end
      end

      context "geo_distance facet" do
        should "encode facet options" do
          f = Facet.new('geo_distance') { geo_distance :location, {:lat => 50, :lon => 9}, [{:to => 1}] }
          assert_equal({:geo_distance => {:geo_distance => {:location => {:lat => 50, :lon => 9}, :ranges => [{:to => 1}]}}}.to_json,
                       f.to_json)
        end

        should "encode custom options" do
          f = Facet.new('geo_distance') { geo_distance :location, {:lat => 50, :lon => 9}, [{:to => 1}],
                                                       :unit => 'km', :value_script => 'doc["field"].value'}
          assert_equal({:geo_distance => {:geo_distance => {:location => {:lat => 50, :lon => 9}, :ranges => [{:to => 1}],
                                                            :unit => "km", :value_script => 'doc["field"].value'}}}.to_json, f.to_json)
        end
      end

      context "filter facet" do

        should "encode facet options" do
          f = Facet.new('filter_facet') do
            filter :term, :tags => 'ruby'
          end
          assert_equal({ :filter_facet => { :filter => { :term => { :tags => 'ruby' } } } }.to_json, f.to_json)
        end

      end

    end

  end

end
