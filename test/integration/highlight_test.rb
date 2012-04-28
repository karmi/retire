require 'test_helper'

module Tire

  class HighlightIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Highlight" do
      teardown { Tire.index('highlight-test').delete }

      should "add 'highlight' field to the result item" do
        # Tire::Configuration.logger STDERR, :level => 'debug'
        s = Tire.search('articles-test') do
          query { string 'Two' }
          highlight :title
        end

        doc = s.results.first

        assert_equal 1, doc.highlight.title.size
        assert doc.highlight.title.to_s.include?('<em>'), "Highlight does not include default highlight tag"
      end

      should "highlight multiple fields with custom highlight tag" do
        s = Tire.search('articles-test') do
          query { string 'Two OR ruby' }
          highlight :tags, :title, :options => { :tag => '<strong>' }
        end

        doc = s.results.first

        assert_equal 1, doc.highlight.title.size
        assert_equal "<strong>Two</strong>", doc.highlight.title.first, "Highlight does not include highlight tag"
        assert_equal "<strong>ruby</strong>", doc.highlight.tags.first, "Highlight does not include highlight tag"
      end

      should "return entire content with highlighted fragments" do
        # Tire::Configuration.logger STDERR, :level => 'debug'

        content = "A Fox one day fell into a deep well and could find no means of escape. A Goat, overcome with thirst, came to the same well, and seeing the Fox, inquired if the water was good. Concealing his sad plight under a merry guise, the Fox indulged in a lavish praise of the water, saying it was excellent beyond measure, and encouraging him to descend. The Goat, mindful only of his thirst, thoughtlessly jumped down, but just as he drank, the Fox informed him of the difficulty they were both in and suggested a scheme for their common escape. \"If,\" said he, \"you will place your forefeet upon the wall and bend your head, I will run up your back and escape, and will help you out afterwards.\" The Goat readily assented and the Fox leaped upon his back. Steadying himself with the Goat horns, he safely reached the mouth of the well and made off as fast as he could. When the Goat upbraided him for breaking his promise, he turned around and cried out, \"You foolish old fellow! If you had as many brains in your head as you have hairs in your beard, you would never have gone down before you had inspected the way up, nor have exposed yourself to dangers from which you had no means of escape.\" Look before you leap."

        Tire.index 'highlight-test' do
          delete
          create
          store   :id => 1, :content => content
          refresh
        end

        s = Tire.search('highlight-test') do
          query { string 'fox' }
          highlight :content => { :number_of_fragments => 0 }
        end

        doc = s.results.first
        assert_not_nil doc.highlight.content

        highlight = doc.highlight.content
        assert highlight.to_s.include?('<em>'), "Highlight does not include default highlight tag"
      end

    end

  end
end
