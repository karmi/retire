require 'test_helper'

module Tire

  class ExplanationIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Explanation" do
      teardown { Tire.index('explanation-test').delete }

      setup do
        content = "A Fox one day fell into a deep well and could find no means of escape. A Goat, overcome with thirst, came to the same well, and seeing the Fox, inquired if the water was good. Concealing his sad plight under a merry guise, the Fox indulged in a lavish praise of the water, saying it was excellent beyond measure, and encouraging him to descend. The Goat, mindful only of his thirst, thoughtlessly jumped down, but just as he drank, the Fox informed him of the difficulty they were both in and suggested a scheme for their common escape. \"If,\" said he, \"you will place your forefeet upon the wall and bend your head, I will run up your back and escape, and will help you out afterwards.\" The Goat readily assented and the Fox leaped upon his back. Steadying himself with the Goat horns, he safely reached the mouth of the well and made off as fast as he could. When the Goat upbraided him for breaking his promise, he turned around and cried out, \"You foolish old fellow! If you had as many brains in your head as you have hairs in your beard, you would never have gone down before you had inspected the way up, nor have exposed yourself to dangers from which you had no means of escape.\" Look before you leap."

        Tire.index 'explanation-test' do
          delete
          create
          store   :id => 1, :content => content
          refresh
        end
      end

      should "add '_explanation' field to the result item" do
        # Tire::Configuration.logger STDERR, :level => 'debug'
        s = Tire.search 'explanation-test', :explain => true do
          query do
            boolean do
              should   { string 'content:Fox' }
            end
          end
        end

        doc = s.results.first

        explanation = doc._explanation

        assert explanation.description.include?("product of:")
        assert explanation.value < 0.6
        assert_not_nil explanation.details
        end

      end

    end
  end
