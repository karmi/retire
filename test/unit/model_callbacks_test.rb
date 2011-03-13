require 'test_helper'

class ModelOne
  include Slingshot::Model::Search
  include Slingshot::Model::Callbacks

  def save;       false; end
  def destroy;    false; end
end

class ModelTwo
  extend  ActiveModel::Callbacks
  define_model_callbacks :save, :destroy

  include Slingshot::Model::Search
  include Slingshot::Model::Callbacks

  def save
    _run_save_callbacks {}
  end

  def destroy
    _run_destroy_callbacks { @destroyed = true }
  end

  def destroyed?; !!@destroyed; end
end

class ModelThree
  extend  ActiveModel::Callbacks
  define_model_callbacks :save, :destroy

  include Slingshot::Model::Search
  include Slingshot::Model::Callbacks

  def save
    _run_save_callbacks {}
  end

  def destroy
    _run_destroy_callbacks {}
  end
end

module Slingshot
  module Model

    class ModelCallbacksTest < Test::Unit::TestCase

      context "Model without ActiveModel callbacks" do

        should "not execute any callbacks" do
          ModelOne.any_instance.expects(:update_elastic_search_index).never

          ModelOne.new.save
          ModelOne.new.destroy
        end

      end

      context "Model with ActiveModel callbacks and implemented destroyed? method" do

        should "execute the callbacks" do
          ModelTwo.any_instance.expects(:update_elastic_search_index).twice

          ModelTwo.new.save
          ModelTwo.new.destroy
        end

      end

      context "Model with ActiveModel callbacks without destroyed? method implemented" do

        should "defined the destroyed? method" do
          assert_respond_to ModelThree.new, :destroyed?
        end

        should "execute the callbacks" do
          ModelThree.any_instance.expects(:update_elastic_search_index).twice

          ModelThree.new.save
          ModelThree.new.destroy
        end

      end

    end

  end
end
