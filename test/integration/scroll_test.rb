require 'test_helper'

module Tire

  class ScrollIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Scroll" do
      setup do
        documents = (1..100).map { |i| { id: i, type: 'test', title: "Document #{i}" } }

        Tire.index 'scrolltest' do
          delete
          create :settings => { :number_of_shards => 1, :number_of_replicas => 0 }
          import documents
          refresh
        end
      end

      teardown { Index.new('scrolltest').delete }

      should "iterate over batches of documents" do
        ids = Array(1..100)
        count = 0

        s = Tire.scroll 'scrolltest'
        s.each do |results|
          results.each { |item| ids.delete(item.id.to_i) }
          count += 1
        end

        assert_empty ids
        assert_equal 10, count
      end

      should "iterate over individual documents" do
        ids = Array(1..100)
        count = 0

        s = Tire.scroll 'scrolltest'
        s.each_document { |results| ids.delete(results.id.to_i); count += 1 }

        assert_empty ids
        assert_equal 100, count
      end

      should "iterate over the individual documents in order" do
        i = 100
        s = Tire.scroll('scrolltest') { sort { by 'id', 'desc' } }
        s.each_document do |results|
          assert results.id.to_i == i, results.inspect
          i -= 1
        end
      end

      should "limit the returned results by query" do
        count = 0

        s = Tire.scroll('scrolltest') { query { string '10*' } }
        s.each do |results|
          count += 1
          assert_equal ['Document 10', 'Document 100'], results.map(&:title)
        end

        assert_equal 1, count
      end

      should "scan over batches of documents" do
        ids = Array(1..100)
        count = 0

        s = Tire.scan 'scrolltest'
        s.each do |results|
          results.each { |item| ids.delete(item.id.to_i) }
          count += 1
        end

        assert_empty ids
        assert_equal 10, count
      end

    end

  end

end
