require 'test_helper'
#require File.expand_path('../../models/supermodel_article', __FILE__)

module Tire

  class SearchResponseIntegrationTest < Test::Unit::TestCase
        include Test::Integration

    class ::ActiveModelArticleWithTitle < ActiveModelArticleWithCallbacks
      mapping do
        indexes :title, type: :string
      end
    end

    class ::ActiveModelArticleWithMalformedTitle < ActiveModelArticleWithCallbacks
      mapping do
        indexes :title, type: :string
      end

      def to_indexed_json
        json = JSON.parse(super)
        json["title"] = { key: "value" }
        json.to_json
      end
    end

    def setup
      super
      ActiveModelArticleWithTitle.index.delete
      ActiveModelArticleWithMalformedTitle.index.delete
    end

    def teardown
      super
      ActiveModelArticleWithTitle.index.delete
      ActiveModelArticleWithMalformedTitle.index.delete
    end

    context "Successful index update" do

      setup do
        @model = ActiveModelArticleWithTitle.new \
                   :id      => 1,
                   :title   => 'Test article',
                   :content => 'Lorem Ipsum. Dolor Sit Amet.'
        @response = @model.update_index
      end

      should "expose the index response on successful update" do
        assert_equal @response.response["ok"], true
      end

    end

    context "Unsuccessful index update" do
      setup do
        ActiveModelArticleWithMalformedTitle.create_elasticsearch_index
        @model = ActiveModelArticleWithMalformedTitle.new \
                   :id      => 1,
                   :title   => 'Test article',
                   :content => 'Lorem Ipsum. Dolor Sit Amet.'
        @response = @model.update_index
      end

      should "expose the index response on update error" do
        assert_equal @response.response["status"], 400
      end
    end
  end
end