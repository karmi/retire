require 'test_helper'

module Tire::Search

  class HighlightTest < Test::Unit::TestCase

    context "Highlight" do

      should "be serialized to JSON" do
        assert_respond_to Highlight.new(:body), :to_json
      end

      should "specify highlight for single field" do
        assert_equal( {:fields => { :body => {} }}.to_json,
                      Highlight.new(:body).to_json )
      end

      should "specify highlight for more fields" do
        assert_equal( {:fields => { :title => {}, :body => {} }}.to_json,
                      Highlight.new(:title, :body).to_json )
      end

      should "specify highlight for more fields with options" do
        assert_equal( {:fields => { :title => {}, :body => { :a => 1, :b => 2 } }}.to_json,
                      Highlight.new(:title, :body => { :a => 1, :b => 2 }).to_json )
      end

      should "specify highlight for more fields with highlight options" do
        # p Highlight.new(:title, :body => {}, :options => { :tag => '<strong>' }).to_hash
        assert_equal( {:fields => { :title => {}, :body => {} }, :pre_tags => ['<strong>'], :post_tags => ['</strong>'] }.to_json,
                      Highlight.new(:title, :body => {}, :options => { :tag => '<strong>' }).to_json )
      end
    
      context "with custom tags" do

        should "properly parse tags with class" do
          assert_equal( {:fields => { :title => {} }, :pre_tags => ['<strong class="highlight">'], :post_tags => ['</strong>'] }.to_json,
                        Highlight.new(:title, :options => { :tag => '<strong class="highlight">' }).to_json )
        end

      end

    end

  end
end
