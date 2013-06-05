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

class MyModelForIndexCreate
  extend  ActiveModel::Naming
  include Tire::Model::Search
end

module Tire
  module Model

    class ModelInitializationTest < Test::Unit::TestCase

      context "Model initialization" do

        should "display a warning and not raise exception when creating the index fails" do
          assert_nothing_raised do
            STDERR.expects(:puts)
            result = ModelWithIncorrectMapping.create_elasticsearch_index
            assert ! result, result.inspect
          end
        end

        should "re-raise non-connection related exceptions" do
          Tire::Index.any_instance.expects(:exists?).raises(ZeroDivisionError)

          assert_raise(ZeroDivisionError) do
            result = MyModelForIndexCreate.create_elasticsearch_index
            assert ! result, result.inspect
          end
        end

        unless defined?(Curl)

          should "display a warning and not raise exception when cannot connect to Elasticsearch (default client)" do
            Tire::Index.any_instance.expects(:exists?).raises(Errno::ECONNREFUSED)
            assert_nothing_raised do
              STDERR.expects(:puts)
              result = MyModelForIndexCreate.create_elasticsearch_index
              assert ! result, result.inspect
            end
          end

        else
          should "display a warning and not raise exception when cannot connect to Elasticsearch (Curb client)" do
            Tire::Index.any_instance.expects(:exists?).raises(::Curl::Err::HostResolutionError)
            assert_nothing_raised do
              STDERR.expects(:puts)
              result = MyModelForIndexCreate.create_elasticsearch_index
              assert ! result, result.inspect
            end
          end

        end

      end
    end
  end
end
