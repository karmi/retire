require 'test_helper'

module Slingshot
  module Model

    class ActiveModelLintTest < Test::Unit::TestCase

      include ActiveModel::Lint::Tests

      def setup
        @model = PersistentArticle.new :title => 'Test'
      end

    end

  end
end
