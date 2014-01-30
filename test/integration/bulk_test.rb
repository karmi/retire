require 'test_helper'

module Tire

  class BulkIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Bulk" do
      setup do
        @index    = Tire.index('bulk-test') { delete; create }
        @articles = [
          { id: '1', type: 'article', title: 'one',   tags: ['ruby']           },
          { id: '2', type: 'article', title: 'two',   tags: ['ruby', 'python'] },
          { id: '3', type: 'article', title: 'three', tags: ['java']           }
        ]
      end

      teardown do
        @index.delete
        Tire.index('bulk-test-fresh').delete
        Tire.index('bulk-test-consistency').delete
        Tire.index('bulk-test-routing').delete
      end

      should "store a collection of documents and refresh the index" do
        @index.bulk_store @articles, refresh: true
        assert_equal 3, Tire.search('bulk-test/article').query { all }.results.size
      end

      should "extract the routing value from documents" do
        index = Tire.index('bulk-test-routing')
        index.delete
        index.create index: { number_of_shards: 2, number_of_replicas: 0 }
        index.bulk_store [ { id: '1', title: 'A', _routing: 'a'}, { id: '2', title: 'B', _routing: 'b'} ]
        index.refresh

        assert_equal 2, Tire.search('bulk-test-routing') { query {all} }.results.size
        assert_equal 1, Tire.search('bulk-test-routing', routing: 'a') { query {all} }.results.size
        assert_equal 1, Tire.search('bulk-test-routing', routing: 'b') { query {all} }.results.size
      end

      should "delete documents in bulk" do
        (1..10).to_a.each { |i| @index.store id: i }
        @index.refresh
        assert_equal 10, Tire.search('bulk-test') { query {all} }.results.size

        documents = (1..10).to_a.map { |i| { id: i } }
        @index.bulk_delete documents, refresh: true
        assert_equal 0, Tire.search('bulk-test') { query {all} }.results.size
      end

      should 'update documents in bulk' do
        @index.bulk_store @articles, refresh: true

        documents = @articles.map do |a|
          {
            id: a[:id],
            type: a[:type],
            doc: { title: "#{a[:title]}-updated" }
          }
        end
        @index.bulk_update documents, refresh: true

        documents = Tire.search('bulk-test') { query {all} }.results.to_a.sort { |a,b| a.id <=> b.id }
        assert_equal 'one-updated', documents[0][:title]
        assert_equal 'two-updated', documents[1][:title]
        assert_equal 'three-updated', documents[2][:title]
      end

      should "allow to feed search results to bulk API" do
        (1..10).to_a.each { |i| @index.store id: i }
        @index.refresh
        assert_equal 10, Tire.search('bulk-test') { query {all} }.results.size

        documents = Tire.search('bulk-test') { query {all} }.results.to_a

        @index.bulk_delete documents, refresh: true
        assert_equal 0, Tire.search('bulk-test') { query {all} }.results.size

        Tire.index('bulk-test-fresh').bulk_create documents, refresh: true
        assert_equal 10, Tire.search('bulk-test-fresh') { query {all} }.results.size
      end

      should "timeout when consistency factor is not met" do
        # Tire.configure { logger STDERR, level: 'debug' }

        Tire.index 'bulk-test-consistency' do
          delete
          create index: { number_of_shards: 1, number_of_replicas: 15 }
        end

        assert_raise Timeout::Error do
          Timeout::timeout(3) do
            Tire.index('bulk-test-consistency').bulk_store [ {id: '1', title: 'One' } ],
                                               consistency: 'all',
                                               raise: true
          end
        end
      end

      should "take external versioning into account" do
        # Tire.configure { logger STDERR, level: 'verbose' }
        index = Tire.index 'bulk-test-external-versioning' do
          delete
          create
          store id: '1', title: 'A', _version: 10, _version_type: 'external'
        end

        response = index.bulk_store [ { id: '1', title: 'A', _version: 0, _version_type: 'external'} ]

        assert_match /VersionConflictEngineException/, MultiJson.load(response.body)['items'][0]['index']['error']
      end
    end

  end

end
