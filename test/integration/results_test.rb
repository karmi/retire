require 'test_helper'

module Tire

  class ResultsIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Query results" do

      should "allow easy access to returned documents" do
        q = 'title:one'
        s = Tire.search('articles-test') { query { string q } }
        assert_equal 'One',  s.results.first.title
        assert_equal 'ruby', s.results.first.tags[0]
      end

      should "allow easy access to returned documents with limited fields" do
        q = 'title:one'
        s = Tire.search('articles-test') { query { string q }.fields :title }
        assert_equal 'One', s.results.first.title
        assert_nil s.results.first.tags
      end

    end

  end

end
