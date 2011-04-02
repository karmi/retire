require 'test_helper'

module Slingshot

  class HighlightIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Highlight" do 

      should "add 'highlight' field to the result item" do
        # Slingshot::Configuration.logger STDERR, :level => 'debug'
        s = Slingshot.search('articles-test') do
          query { string 'Two' }
          highlight :title
        end

        doc = s.results.first

        assert_equal 1, doc.highlight.title.size
        assert doc.highlight.title.to_s.include?('<em>'), "Highlight does not include default highlight tag"
      end

    end

  end
end
