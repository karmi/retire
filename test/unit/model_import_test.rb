require 'test_helper'

class ImportModel
  extend  ActiveModel::Naming
  include Tire::Model::Search
  include Tire::Model::Callbacks

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

module Tire
  module Model

    class ImportTest < Test::Unit::TestCase

      context "Model::Import" do

        should "have the import method" do
          assert_respond_to ImportModel, :import
        end

        should "paginate the results by default when importing" do
          Tire::Index.any_instance.expects(:bulk_store).returns(true).times(2)

          ImportModel.import :per_page => 2
        end

        should "call the passed block on every batch, and NOT manipulate the documents array" do
          Tire::Index.any_instance.expects(:bulk_store).with { |c,o| c == [1, 2] }
          Tire::Index.any_instance.expects(:bulk_store).with { |c,o| c == [3, 4] }

          runs = 0
          ImportModel.import :per_page => 2 do |documents|
            runs += 1
            # Don't forget to return the documents at the end of the block
            documents
          end

          assert_equal 2, runs
        end

        should "manipulate the documents in passed block" do
          Tire::Index.any_instance.expects(:bulk_store).with { |c,o| c == [2, 3] }
          Tire::Index.any_instance.expects(:bulk_store).with { |c,o| c == [4, 5] }

          ImportModel.import :per_page => 2 do |documents|
            # Add 1 to every "document" and return them
            documents.map { |d| d + 1 }
          end
        end

        should "store the documents in a different index" do
          Tire::Index.expects(:new).with('new_index').returns( mock('index') { expects(:import) } )
          ImportModel.import :index => 'new_index'
        end

        context 'Strategy' do
          class ::CustomImportStrategy
            include Tire::Model::Import::Strategy::Base
          end

          should 'return explicitly specified strategy from predefined strategies' do
            strategy = Tire::Model::Import::Strategy.from_class(ImportModel, :strategy => 'WillPaginate')
            assert_equal strategy.class.name, 'Tire::Model::Import::Strategy::WillPaginate'
          end

          should 'return custom strategy class' do
            strategy = Tire::Model::Import::Strategy.from_class(ImportModel, :strategy => 'CustomImportStrategy')
            assert_equal strategy.class.name, 'CustomImportStrategy'
          end

        end

      end

    end

  end
end
