require 'test_helper'

module Slingshot

  class QueryStringIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Searching for query string" do

      should "find article by title" do
        s = Slingshot.search 'articles-test' do
          query  { string 'title:one' }
        end
        assert_equal 1, s.results.count
        assert_equal 'One', s.results.first['_source']['title']
      end

    end

  end

end
