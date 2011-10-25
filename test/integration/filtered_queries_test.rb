require 'test_helper'

module Tire

  class FilteredQueriesIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Filtered queries" do

      should "filter the results" do
        # 2.json > Begins with "T" and is tagged "ruby"

        s = Tire.search('articles-test') do
          query do
            filtered do
              query { string 'title:T*' }
              filter :terms, :tags => ['ruby']
            end
          end
        end

        assert_equal 1, s.results.count
        assert_equal 'Two', s.results.first.title
      end

    end

  end

end
