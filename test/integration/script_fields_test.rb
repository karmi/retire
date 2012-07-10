require 'test_helper'

module Tire

  class ScriptFieldsIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "ScriptFields" do

      should "add multiple fields to the results" do
        # 1.json > title: "One", words: 125

        s = Tire.search('articles-test') do
          query { string "One" }
          script_field :double_words, :script => "doc['words'].value * 2"
          script_field :triple_words, :script => "doc['words'].value * 3"
        end

        assert_equal 250, s.results.first.double_words
        assert_equal 375, s.results.first.triple_words
      end

      should "allow passing parameters to the script" do
        # 1.json > title: "One", words: 125

        s = Tire.search('articles-test') do
          query { string "One" }
          script_field :double_words, :script => "doc['words'].value * factor", :params => { :factor => 2 }
        end

        assert_equal 250, s.results.first.double_words
      end

    end

  end

end
