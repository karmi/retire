require 'test_helper'

module Tire

  class WildcardQueriesIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Wildcard queries" do

      should "allow simple wildcard queries" do
        s = Tire.search('articles-test') do
          query do
            wildcard "title", "f*"
          end
        end

        assert_equal 2, s.results.size
        assert_equal ['Five', 'Four'].sort, s.results.map(&:title).sort
      end

    end

  end

end
