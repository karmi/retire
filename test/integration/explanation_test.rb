require 'test_helper'

module Tire

  class ExplanationIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Explanation" do
      teardown { Tire.index('explanation-test').delete }

      setup do
        content = "A Fox one day fell into a deep well and could find no means of escape."

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

        assert explanation.description.include?("result of:")
        assert explanation.value < 0.6
        assert_not_nil explanation.details
        end

      end

    end
  end
