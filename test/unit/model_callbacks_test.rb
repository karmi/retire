require 'test_helper'

class ModelOne
  extend  ActiveModel::Naming
  include Tire::Model::Search
  include Tire::Model::Callbacks

  def save;       false; end
  def destroy;    false; end
end

class ModelTwo
  extend ActiveModel::Naming
  extend ActiveModel::Callbacks
  define_model_callbacks :save, :destroy

  include Tire::Model::Search
  include Tire::Model::Callbacks

  def save;    _run_save_callbacks {};                       end
  def destroy; _run_destroy_callbacks { @destroyed = true }; end

  def destroyed?; !!@destroyed; end
end

class ModelThree
  extend ActiveModel::Naming
  extend ActiveModel::Callbacks
  define_model_callbacks :save, :destroy

  include Tire::Model::Search
  include Tire::Model::Callbacks

  def save;    _run_save_callbacks {};    end
  def destroy; _run_destroy_callbacks {}; end
end

class ModelWithoutTireAutoCallbacks
  extend ActiveModel::Naming
  extend ActiveModel::Callbacks
  define_model_callbacks :save, :destroy

  include Tire::Model::Search
  # DO NOT include Callbacks

  def save;    _run_save_callbacks {};    end
  def destroy; _run_destroy_callbacks {}; end
end

module Tire
  module Model

    class ModelCallbacksTest < Test::Unit::TestCase

      context "Model without ActiveModel callbacks" do

        should "not execute any callbacks" do
          m = ModelOne.new
          m.tire.expects(:update_index).never

          m.save
          m.destroy
        end

      end

      context "Model with ActiveModel callbacks and implemented destroyed? method" do

        should "execute the callbacks" do
          m = ModelTwo.new
          m.tire.expects(:update_index).twice

          m.save
          m.destroy
        end

      end

      context "Model with ActiveModel callbacks without destroyed? method implemented" do

        should "have the destroyed? method added" do
          assert_respond_to ModelThree.new, :destroyed?
        end

        should "execute the callbacks" do
          m = ModelThree.new
          m.tire.expects(:update_index).twice

          m.save
          m.destroy
        end

      end

      context "Model without Tire::Callbacks included" do

        should "respond to Tire update_index callbacks" do
          assert_respond_to ModelWithoutTireAutoCallbacks, :after_update_elasticsearch_index
          assert_respond_to ModelWithoutTireAutoCallbacks, :before_update_elasticsearch_index
        end

        should "not execute the update_index hooks" do
          m = ModelWithoutTireAutoCallbacks.new
          m.tire.expects(:update_index).never

          m.save
          m.destroy
        end
      end

      # ---------------------------------------------------------------------------

    end

  end
end
