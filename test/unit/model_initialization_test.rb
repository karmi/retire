require 'test_helper'

class ModelWithIncorrectMapping
  extend  ActiveModel::Naming
  include Tire::Model::Search
  include Tire::Model::Callbacks

  tire do
    mapping do
      indexes :title, :type => 'boo'
    end
  end
end

module Tire
  module Model

    class ModelInitializationTest < Test::Unit::TestCase

      context "Model initialization" do

        should "display a warning when creating the index fails" do
          STDERR.expects(:puts)
          result = ModelWithIncorrectMapping.create_elasticsearch_index
          assert ! result, result.inspect
        end

      end
    end
  end
end
