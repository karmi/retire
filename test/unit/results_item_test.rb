require 'test_helper'

module Tire
  class ResultsItemTest < Test::Unit::TestCase

    # ActiveModel compatibility tests
    #
    def setup
      super
      begin; Object.send(:remove_const, :Rails); rescue; end
      @model = Results::Item.new :title => 'Test'
    end
    include ActiveModel::Lint::Tests

    context "Item" do

      setup do
        @document = Results::Item.new :title  => 'Test',
                                      :author => { :name => 'Kafka' },
                                      :awards => { :best_fiction => { :year => '1925' } }
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

      should "have an 'id' method" do
        a = Results::Item.new(:_id => 1)
        b = Results::Item.new(:id => 1)
        assert_equal 1, a.id
        assert_equal 1, b.id
      end

      should "have a 'type' method" do
        a = Results::Item.new(:_type => 'foo')
        b = Results::Item.new(:type => 'foo')
        assert_equal 'foo', a.type
        assert_equal 'foo', b.type
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

      should "implement respond_to? for proxied methods" do
        assert @document.respond_to?(:title)
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

      should "not care about symbols or strings in composite keys" do
        @document = Results::Item.new :highlight => { 'name.ngrams' => 'abc' }

        assert_not_nil @document.highlight['name.ngrams']
        assert_equal   'abc', @document.highlight['name.ngrams']
        assert_equal   @document.highlight['name.ngrams'], @document.highlight['name.ngrams'.to_sym]
      end

      should "allow to retrieve values from nested hashes" do
        assert_not_nil   @document.author.name
        assert_equal 'Kafka', @document.author.name
      end

      should "wrap arrays" do
        @document = Results::Item.new :stats => [1, 2, 3]
        assert_equal [1, 2, 3], @document.stats
      end

      should "wrap hashes in arrays" do
        @document = Results::Item.new :comments => [{:title => 'one'}, {:title => 'two'}]
        assert_equal 2,    @document.comments.size
        assert_instance_of Results::Item, @document.comments.first
        assert_equal       'one', @document.comments.first.title
        assert_equal       'two', @document.comments.last.title
      end

      should "be an Item instance" do
        assert_instance_of Tire::Results::Item, @document
      end

      should "be convertible to hash" do
        assert_instance_of Hash, @document.to_hash
        assert_instance_of Hash, @document.to_hash[:author]
        assert_instance_of Hash, @document.to_hash[:awards][:best_fiction]

        assert_equal 'Kafka', @document.to_hash[:author][:name]
        assert_equal '1925',  @document.to_hash[:awards][:best_fiction][:year]
      end

      should "be inspectable" do
        assert_match /<Item .* title|Item .* author/, @document.inspect
      end

      context "within Rails" do

        setup do
          module ::Rails
          end

          class ::FakeRailsModel
            extend  ActiveModel::Naming
            include ActiveModel::Conversion
            def self.find(id, options); new; end
          end

          @document = Results::Item.new :id => 1, :_type => 'fake_rails_model', :title => 'Test'
        end

        should "be an instance of model, based on _type" do
          assert_equal FakeRailsModel, @document.class
        end

        should "be inspectable with masquerade" do
          assert_match /<Item \(FakeRailsModel\)/, @document.inspect
        end

        should "return proper singular and plural forms" do
          assert_equal 'fake_rails_model',  ActiveModel::Naming.singular(@document)
          assert_equal 'fake_rails_models', ActiveModel::Naming.plural(@document)
        end

        should "instantiate itself for deep hashes, not a Ruby class corresponding to type" do
          document = Results::Item.new :_type => 'my_model', :title => 'Test', :author => { :name => 'John' }

          assert_equal Tire::Results::Item, document.class
        end

      end

    end

  end

end
