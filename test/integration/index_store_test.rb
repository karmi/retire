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

      teardown do
        Tire.index('articles-test-ids').delete
        Tire.index('articles-test-types').delete
      end

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

      should "store documents as proper types" do
        Tire.index 'articles-test-types' do
          delete
          create
          store :type => 'my_type', :title => 'One'
          refresh
        end

        s = Tire.search('articles-test-types/my_type') { query { all } }
        assert_equal 1, s.results.count
        assert_equal 'my_type', s.results.first.type
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

    context "Retrieving documents from the index" do

      teardown { Tire.index('articles-test-retrieve').delete }

      setup do
        Tire.index 'articles-test-retrieve' do
          delete
          create
          store :id => 1, :title => 'One'
          store :id => 2, :title => 'Two'
          refresh
        end
      end

      should "retrieve document from the index" do
        assert_instance_of Tire::Results::Item, Tire.index('articles-test-retrieve').retrieve(:document, 1)
      end

      should "return nil when retrieving missing document" do
        assert_nil Tire.index('articles-test-retrieve').retrieve :document, 4
      end

    end

  end

end
