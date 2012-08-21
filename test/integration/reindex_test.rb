require 'test_helper'

module Tire

  class ReindexIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Reindex" do
      setup do
        Tire.index('reindex-test-new').delete

        documents = (1..100).map { |i| { id: i, type: 'test', title: "Document #{i}" } }

        Tire.index 'reindex-test' do
          delete
          create :settings => { :number_of_shards => 1, :number_of_replicas => 0 }
          import documents
          refresh
        end
      end

      teardown do
        Index.new('reindex-test').delete
        Index.new('reindex-test-new').delete
      end

      should "reindex the index into a new index with different settings" do
        Tire.index('reindex-test').reindex 'reindex-test-new', settings: { number_of_shards: 3 }

        Tire.index('reindex-test-new').refresh
        assert_equal 100, Tire.search('reindex-test-new').results.total
        assert_equal '3', Tire.index('reindex-test-new').settings['index.number_of_shards']
      end

      should "reindex a portion of an index into a new index" do
        Tire.index('reindex-test').reindex('reindex-test-new') { query { string '10*' } }
        
        Tire.index('reindex-test-new').refresh
        assert_equal 2, Tire.search('reindex-test-new').results.total
      end

      should "transform documents with a passed lambda" do
        Tire.index('reindex-test').reindex 'reindex-test-new', transform: lambda { |document|
                                                                            document[:title] += 'UPDATED'
                                                                            document
                                                                          }

        Tire.index('reindex-test-new').refresh
        assert_match /UPDATED/, Tire.search('reindex-test-new').results.first.title
      end

    end

  end

end
