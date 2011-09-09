require 'test_helper'

module Tire

  class IndexStoreIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Storing the documents in index" do

      setup do
        Tire.index 'articles-test-ids' do
          delete
          create

          store :id => 1, :title => 'One'
          store :id => 2, :title => 'Two'
          store :id => 3, :title => 'Three'
          store :id => 4, :title => 'Four'
          store :id => 4, :title => 'Four'

          refresh
        end
      end

      teardown { Tire.index('articles-test-ids').delete }

      should "happen in existing index" do
        assert   Tire.index("articles-test-ids").exists?
        assert ! Tire.index("four-oh-four-index").exists?
      end

      should "store hashes under their IDs" do
        s = Tire.search('articles-test-ids') { query { string '*' } }

        assert_equal 4, s.results.count

        document = Tire.index('articles-test-ids').retrieve :document, 4
        assert_equal 'Four', document.title
        assert_equal 2,      document._version.to_i

      end

    end

    context "Removing documents from the index" do

      teardown { Tire.index('articles-test-remove').delete }

      setup do
        Tire.index 'articles-test-remove' do
          delete
          create
          store :id => 1, :title => 'One'
          store :id => 2, :title => 'Two'
          refresh
        end
      end

      should "remove document from the index" do

        assert_equal 2, Tire.search('articles-test-remove') { query { string '*' } }.results.count

        assert_nothing_raised do
          assert Tire.index('articles-test-remove').remove 1
          assert ! Tire.index('articles-test-remove').remove(1)
        end

      end

    end

  end

end
