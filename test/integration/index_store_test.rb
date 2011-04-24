require 'test_helper'

module Slingshot

  class IndexStoreIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Storing the documents in index" do

      teardown { Slingshot.index('articles-test-ids').delete }

      should "store hashes under their IDs" do

        Slingshot.index 'articles-test-ids' do
          delete
          create

          store :id => 1, :title => 'One'
          store :id => 2, :title => 'Two'
          store :id => 3, :title => 'Three'
          store :id => 4, :title => 'Four'
          store :id => 4, :title => 'Four'

          refresh
        end

        s = Slingshot.search('articles-test-ids') { query { string '*' } }

        assert_equal 4, s.results.count

        document = Slingshot.index('articles-test-ids').retrieve :document, 4
        assert_equal 'Four', document.title
        assert_equal 2,      document._version.to_i

      end

    end

  end

end
