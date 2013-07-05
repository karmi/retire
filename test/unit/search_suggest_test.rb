require 'test_helper'

module Tire::Search

  class SuggestTest < Test::Unit::TestCase

    context "Suggest" do

      should "be serialized to JSON" do
        assert_respond_to Suggest.new('foo', 'bar'), :to_json
      end

      should "allow you to specify name and text" do
        assert_equal( { :suggest_name => { :text => "suggest_text"}}.to_json,
                      Suggest.new(:suggest_name, "suggest_text").to_json)
      end

      should "allow you to specify additional options" do
        assert_equal( { :suggest_name => { :text => "suggest_text", :option1 => "option_value"}}.to_json,
                      Suggest.new(:suggest_name, "suggest_text", :option1 => "option_value").to_json)
      end

      context "term suggest" do
        should "allow you to specify the field to fetch the candidate suggestions from" do
          suggest = Suggest.new :suggest_name, "suggest_text" do
            term "candidate_field"
          end

          assert_equal( { :suggest_name => { :text => "suggest_text", :term => { :field => "candidate_field" }}}.to_json,
                        suggest.to_json)
        end

        should "allow you to specify term suggest options" do
          suggest = Suggest.new :suggest_name, "suggest_text" do
            term "candidate_field", :size => 3, :sort => "frequency"
          end

          assert_equal( { :suggest_name => { :text => "suggest_text", :term => { :field => "candidate_field", :size => 3, :sort => "frequency" }}}.to_json,
                        suggest.to_json)
        end
      end

      context "phrase suggest" do
        should "allow you to specify the name of the field used to do n-gram lookups for the language model" do
          suggest = Suggest.new :suggest_name, "suggest_text" do
            phrase "candidate_field"
          end

          assert_equal( { :suggest_name => { :text => "suggest_text", :phrase => { :field => "candidate_field" }}}.to_json,
                        suggest.to_json)
        end

        should "allow you to specify phrase suggest options" do
          suggest = Suggest.new :suggest_name, "suggest_text" do
            phrase "candidate_field", :gram_size => 2, :max_errors => 0.5
          end

          assert_equal( { :suggest_name => { :text => "suggest_text", :phrase => { :field => "candidate_field", :gram_size => 2, :max_errors => 0.5 }}}.to_json,
                        suggest.to_json)
        end

        should "allow you to specify the smoothing model" do
          suggest = Suggest.new :suggest_name, "suggest_text" do
            phrase "candidate_field" do
              smoothing :stupid_backoff, :discount => 0.5
            end
          end

          assert_equal( { :suggest_name => { :text => "suggest_text", :phrase => { :field => "candidate_field", :smoothing => { :stupid_backoff => { :discount => 0.5 }} }}}.to_json,
                        suggest.to_json)
        end

        should "allow you to specify a direct generator" do
          suggest = Suggest.new :suggest_name, "suggest_text" do
            phrase "candidate_field" do
              generator "generator_field"
            end
          end

          assert_equal( { :suggest_name => { :text => "suggest_text", :phrase => { :field => "candidate_field", :direct_generator => [ { :field => "generator_field" } ] }}}.to_json,
                        suggest.to_json)
        end

        should "allow you to specify a direct generator options" do
          suggest = Suggest.new :suggest_name, "suggest_text" do
            phrase "candidate_field" do
              generator "generator_field", :min_word_len => 1
            end
          end

          assert_equal( { :suggest_name => { :text => "suggest_text", :phrase => { :field => "candidate_field", :direct_generator => [ { :field => "generator_field", :min_word_len => 1 } ] }}}.to_json,
                        suggest.to_json)
        end

        should "allow you to specify multiple direct generators" do
          suggest = Suggest.new :suggest_name, "suggest_text" do
            phrase "candidate_field" do
              generator "generator_field"
              generator "generator_field2"
            end
          end

          assert_equal( { :suggest_name => { :text => "suggest_text", :phrase => { :field => "candidate_field", :direct_generator => [ { :field => "generator_field" }, { :field => "generator_field2" } ] }}}.to_json,
                        suggest.to_json)
        end
      end

    end
  end
end
