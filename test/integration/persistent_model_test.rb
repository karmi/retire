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
    end

    context "PersistentModel" do

      should "save documents into index and find them by IDs" do
        one = PersistentArticle.create :id => 1, :title => 'One'
        two = PersistentArticle.create :id => 2, :title => 'Two'

        PersistentArticle.index.refresh

        results = PersistentArticle.find [1, 2]

        assert_equal 2, results.size
        
      end

      context "with pagination" do

        setup do
          1.upto(9) { |number| PersistentArticle.create :title => "Test#{number}" }
          PersistentArticle.elasticsearch_index.refresh
        end

        should "find first page with five results" do
          results = PersistentArticle.search( :per_page => 5, :page => 1 ) { query { all } }
          assert_equal 9, results.size

          assert_equal 2, results.total_pages
          assert_equal 1, results.current_page
          assert_equal nil, results.previous_page
          assert_equal 2, results.next_page

          assert_equal 'Test1', results.first.title
        end
      end

    end

  end
end
