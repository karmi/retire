require 'test_helper'

class ImportModel
  extend  ActiveModel::Naming
  include Slingshot::Model::Search
  include Slingshot::Model::Callbacks

  DATA = (1..4).to_a

  def self.paginate(options={})
    options = {:page => 1, :per_page => 1000}.update options
    DATA.slice( (options[:page]-1)*options[:per_page]...options[:page]*options[:per_page] )
  end

  def self.all(options={})
    DATA
  end

  def self.count
    DATA.size
  end
end

module Slingshot
  module Model

    class ImportTest < Test::Unit::TestCase

      context "Model::Import" do

        should "have the import method" do
          assert_respond_to ImportModel, :import
        end

        should "paginate the results by default when importing" do
          Slingshot::Index.any_instance.expects(:bulk_store).returns(true).times(2)

          ImportModel.import :per_page => 2
        end

        should "call the passed block on every batch, and NOT manipulate the documents array" do
          Slingshot::Index.any_instance.expects(:bulk_store).with([1, 2])
          Slingshot::Index.any_instance.expects(:bulk_store).with([3, 4])

          runs = 0
          ImportModel.import :per_page => 2 do |documents|
            runs += 1
            # Don't forget to return the documents at the end of the block
            documents
          end

          assert_equal 2, runs
        end

        should "manipulate the documents in passed block" do
          Slingshot::Index.any_instance.expects(:bulk_store).with([2, 3])
          Slingshot::Index.any_instance.expects(:bulk_store).with([4, 5])

          ImportModel.import :per_page => 2 do |documents|
            # Add 1 to every "document" and return them
            documents.map { |d| d + 1 }
          end

        end

      end

    end

  end
end
