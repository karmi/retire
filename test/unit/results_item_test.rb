require 'test_helper'

module Slingshot

  class ResultsItemTest < Test::Unit::TestCase

    context "Item" do

      setup do
        @document = Results::Item.new :title => 'Test', :author => { :name => 'Kafka' }
      end

      should "be initialized with a Hash" do
        assert_nothing_raised do
          d = Results::Item.new(:id => 1)
          assert_instance_of Results::Item, d
        end
      end

      should "delegate non-Hash params to Hash when initializing" do
        assert_nothing_raised do
          d = Results::Item.new('foo')
          assert_instance_of Results::Item, d
          assert_equal 'foo', d[:bar] # See http://www.ruby-doc.org/core/classes/Hash.html#M000718
        end
      end

      should "respond to :to_indexed_json" do
        assert_respond_to Results::Item.new, :to_indexed_json
      end

      should "retrieve the values from underlying hash" do
        assert_equal 'Test', @document[:title]
      end

      should "allow to retrieve the values by methods" do
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

      should "allow to retrieve hashes" do
        assert_equal 'Kafka', @document.author[:name]
      end

      should "allow to retrieve values from nested hashes" do
        assert_not_nil   @document.author.name
        assert_equal 'Kafka', @document.author.name
      end

    end

  end

end
