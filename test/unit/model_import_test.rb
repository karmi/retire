require 'test_helper'

class ImportModel
  extend  ActiveModel::Naming
  include Slingshot::Model::Search
  include Slingshot::Model::Callbacks

  def self.paginate(options={})
    options = {:page => 0, :per_page => 1000}.update options
    (1..10).to_a.slice( options[:page]*options[:per_page]...(options[:page]+1)*options[:per_page] )
  end
end

module Slingshot
  module Model

    class ImportTest < Test::Unit::TestCase

      context "Model::Import" do

        should "have the import method" do
          assert_respond_to ImportModel, :import
        end

        should "raise errror when model does not have the paginate method" do
          class ::ModelWithNoPagination
            extend  ActiveModel::Naming
            include Slingshot::Model::Search
            include Slingshot::Model::Callbacks
          end

          assert_raise(NoMethodError) { ModelWithNoPagination.import }
        end

        should "paginate the results when importing" do
          Slingshot::Index.any_instance.expects(:bulk_store).returns(true).times(2)

          ImportModel.expects(:paginate).
            returns([1,2]).
            then.returns([3,4]).
            then.returns([]).
            times(3)

          ImportModel.import :per_page => 2
        end

      end

    end

  end
end
