require 'test_helper'

module Tire

  class DSLSearchIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "DSL" do

      should "allow passing search payload as a Hash" do
        s = Tire.search 'articles-test', :query  => { :query_string => { :query => 'ruby' } },
                                         :facets => { 'tags' => { :filter => { :term => {:tags => 'ruby' } } } }

        assert_equal 2, s.results.count
        assert_equal 2, s.results.facets['tags']['count']
      end

      should "allow building search query iteratively" do
        s = Tire.search 'articles-test'
        s.query { string 'T*' }
        s.filter :terms, :tags => ['java']

        assert_equal 1, s.results.count
      end

    end

  end

end
