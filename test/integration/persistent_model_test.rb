require 'test_helper'

module Tire

  class PersistentModelIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    def setup
      super
      PersistentArticle.index.delete
    end

    def teardown
      super
      PersistentArticle.index.delete
      PersistentArticleWithDefaults.index.delete
    end

    context "PersistentModel" do

      should "search with simple query" do
        PersistentArticle.create :id => 1, :title => 'One'
        PersistentArticle.index.refresh

        results = PersistentArticle.search 'one'
        assert_equal 'One', results.first.title
      end

      should "search with a block" do
        PersistentArticle.create :id => 1, :title => 'One'
        PersistentArticle.index.refresh

        results = PersistentArticle.search(:sort => 'title') { query { string 'one' } }
        assert_equal 'One', results.first.title
      end

      should "return instances of model" do
        PersistentArticle.create :id => 1, :title => 'One'
        PersistentArticle.index.refresh

        results = PersistentArticle.search 'one'
        assert_instance_of PersistentArticle, results.first
      end

      should "save documents into index and find them by IDs" do
        one = PersistentArticle.create :id => 1, :title => 'One'
        two = PersistentArticle.create :id => 2, :title => 'Two'

        PersistentArticle.index.refresh

        results = PersistentArticle.find [1, 2]

        assert_equal 2, results.size

      end

      should "return default values for properties without value" do
        PersistentArticleWithDefaults.create :id => 1, :title => 'One'
        PersistentArticleWithDefaults.index.refresh

        results = PersistentArticleWithDefaults.all

        assert_equal [], results.first.tags
      end

      context "with pagination" do

        setup do
          1.upto(9) { |number| PersistentArticle.create :title => "Test#{number}" }
          PersistentArticle.index.refresh
        end

        should "find first page with five results" do
          results = PersistentArticle.search( :per_page => 5, :page => 1 ) { query { all } }
          assert_equal 5, results.size

          # WillPaginate
          #
          assert_equal 2, results.total_pages
          assert_equal 1, results.current_page
          assert_equal nil, results.previous_page
          assert_equal 2, results.next_page

          # Kaminari
          #
          assert_equal 5, results.limit_value
          assert_equal 9, results.total_count
          assert_equal 2, results.num_pages
          assert_equal 0, results.offset_value
        end
      end

    end

  end
end
