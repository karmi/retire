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
    end

  end
end
