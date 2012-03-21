require 'test_helper'

module Tire

  class DSLSearchIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "DSL" do

      should "allow passing search payload as JSON" do
        s = Tire.search 'articles-test', query:  { query_string: { query: 'ruby' } },
                                         facets: { 'current-tags' => { filter: { term: {tags: 'ruby' } } },
                                                   'global-tags'  => { filter: { term: {tags: 'ruby'} }, global: true } }
        # p s.results
        assert_equal 2, s.results.count
        assert_not_nil s.results.facets['current-tags']
        assert_not_nil s.results.facets['global-tags']
      end

    end

  end

end
