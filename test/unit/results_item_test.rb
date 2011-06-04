require 'test_helper'

module Tire

  class ResultsItemTest < Test::Unit::TestCase

    context "Item" do

      setup do
        @document = Results::Item.new :title => 'Test', :author => { :name => 'Kafka' }
      end

      should "be initialized with a Hash or Hash like object" do
        assert_raise(ArgumentError) { Results::Item.new('FUUUUUUU') }

        assert_nothing_raised do
          d = Results::Item.new(:id => 1)
          assert_instance_of Results::Item, d
        end

        assert_nothing_raised do
          class AlmostHash < Hash; end
          d = Results::Item.new(AlmostHash.new(:id => 1))
        end
      end

      should "respond to :to_indexed_json" do
        assert_respond_to Results::Item.new, :to_indexed_json
      end

      should "retrieve simple values from underlying hash" do
        assert_equal 'Test', @document[:title]
      end

      should "retrieve hash values from underlying hash" do
        assert_equal 'Kafka', @document[:author][:name]
      end

      should "allow to retrieve value by methods" do
        assert_not_nil @document.title
        assert_equal 'Test', @document.title
      end

      should "return nil for non-existing keys/methods" do
        assert_nothing_raised { @document.whatever }
        assert_nil @document.whatever
      end

      should "not care about symbols or strings in keys" do
        @document = Results::Item.new 'title' => 'Test'
        assert_not_nil @document.title
        assert_equal 'Test', @document.title
      end

      should "allow to retrieve values from nested hashes" do
        assert_not_nil   @document.author.name
        assert_equal 'Kafka', @document.author.name
      end

    end

  end

end
