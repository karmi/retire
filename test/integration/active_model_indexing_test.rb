require 'test_helper'
require File.expand_path('../../models/supermodel_article', __FILE__)

module Tire

  class ActiveModelSearchableIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    class ::ActiveModelArticleWithCustomAsSerialization < ActiveModelArticleWithCallbacks
      mapping do
        indexes :title
        indexes :content
        indexes :characters,  :as => 'content.length'
        indexes :readability, :as => proc {
                                       content.split(/\W/).reject { |t| t.blank? }.size /
                                       content.split(/\./).size
                                     }
      end
    end

    def setup
      super
      ActiveModelArticleWithCustomAsSerialization.index.delete
    end

    def teardown
      super
      ActiveModelArticleWithCustomAsSerialization.index.delete
    end

    context "ActiveModel serialization" do

      setup do
        @model = ActiveModelArticleWithCustomAsSerialization.new \
                   :id      => 1, 
                   :title   => 'Test article',
                   :content => 'Lorem Ipsum. Dolor Sit Amet.'
        @model.update_index
        @model.index.refresh
      end

      should "serialize the content length" do
        m = ActiveModelArticleWithCustomAsSerialization.search('*').first
        assert_equal 28, m.characters
        assert_equal 2,  m.readability
      end

    end

  end
end
