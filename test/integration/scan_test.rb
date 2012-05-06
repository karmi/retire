require 'test_helper'

module Tire

  class ScanIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Scan" do
      setup do
        documents = (1..100).map { |i| { id: i, type: 'test', title: "Document #{i}" } }

        Tire.index 'scantest' do
          delete
          create :settings => { :number_of_shards => 1, :number_of_replicas => 0 }
          import documents
          refresh
        end
      end

      teardown { Index.new('scantest').delete }

      should "iterate over batches of documents" do
        count = 0

        s = Tire.scan 'scantest'
        s.each { |results| count += 1 }

        assert_equal 10, count
      end

      should "iterate over individual documents" do
        count = 0

        s = Tire.scan 'scantest'
        s.each_document { |results| count += 1 }

        assert_equal 100, count
      end

      should "limit the returned results by query" do
        count = 0

        s = Tire.scan('scantest') { query { string '10*' } }
        s.each do |results|
          count += 1
          assert_equal ['Document 10', 'Document 100'], results.map(&:title)
        end

        assert_equal 1, count
      end

    end

  end

end
