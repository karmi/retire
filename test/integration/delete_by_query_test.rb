require 'test_helper'

module Tire
  class DeleteByQueryIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    should "delete documents matching a query" do
      assert_python_size(1)
      delete_by_query
      assert_python_size(0)
    end

    should "leave documents not matching a query" do
      assert_python_size(1)
      delete_by_query('article', 'go')
      assert_python_size(1)
    end

    should "not delete documents with different types" do
      assert_python_size(1)
      delete_by_query('different_type')
      assert_python_size(1)
    end

    context "DSL" do
      should "delete documents matching a query" do
        assert_python_size(1)
        Tire.delete('articles-test') { term :tags, 'python' }
        assert_python_size(0)
      end
    end

    private

    def delete_by_query(type='article', token='python')
      Tire::DeleteByQuery.new('articles-test', :type => type) do
        term :tags, token
      end.perform
    end

    def assert_python_size(size)
      Tire.index('articles-test').refresh
      search = Tire.search('articles-test') { query { term :tags, 'python' } }
      assert_equal size, search.results.size
    end
  end
end
