require 'test_helper'

module Tire

  class IndexAliasTest < Test::Unit::TestCase

    context "Index Alias" do
      teardown { Configuration.reset }

      context "initialization" do

        should "have a name and defaults" do
          @alias = Alias.new :name => 'dummy'
          assert_equal 'dummy', @alias.name
          assert @alias.indices.empty?
        end

        should "have indices" do
          @alias = Alias.new :indices => ['index_A', 'index_B']
          assert_equal ['index_A', 'index_B'], @alias.indices.to_a
        end

        should "have single index" do
          @alias = Alias.new :index => 'index_A'
          assert_equal ['index_A'], @alias.indices.to_a
          assert_equal ['index_A'], @alias.index.to_a
        end

        should "have properties" do
          @alias = Alias.new :routing => '1'
          assert_equal '1', @alias.routing
        end

        should "allow to add indices in a block" do
          @alias = Alias.new do
            index 'index_A'
            index 'index_B'
          end
          assert_equal ['index_A', 'index_B'], @alias.indices.to_a

          @alias = Alias.new do |a|
            a.index 'index_A'
            a.index 'index_B'
          end
          assert_equal ['index_A', 'index_B'], @alias.indices.to_a
        end

        should "allow to define filter with DSL" do
          @alias = Alias.new do
            filter :terms, :username => 'mary'
          end

          assert_equal( { :terms => { :username => 'mary' } }, @alias.filter )
        end

        should "allow chaining" do
          @alias = Alias.new.name('my_alias').index('index_1').index('index_2').routing('1')

          assert_equal 'my_alias',             @alias.name
          assert_equal ['index_1', 'index_2'], @alias.indices.to_a
          assert_equal '1',                    @alias.routing
        end

        should "be converted to JSON" do
          @alias = Alias.new :name    => 'index_anne',
                             :indices => ['index_2012_04', 'index_2012_03', 'index_2012_02'],
                             :routing => 1,
                             :filter  => { :terms => { :user => 'anne' } }
          # p @alias.to_json
          result = MultiJson.decode @alias.to_json

          assert_equal 3, result['actions'].size
          assert_equal 'index_2012_04', result['actions'][0]['add']['index']
        end

        should "be converted to string" do
          @alias = Alias.new :name => 'my_alias'
          assert_equal 'my_alias', @alias.to_s
        end

      end

      context "updating" do
        setup do
          Configuration.client.expects(:get).
                               returns( mock_response(                               %q|{"index_A":{"aliases":{}},"index_B":{"aliases":{"alias_john":{"filter":{"term":{"user":"john"}}},"alias_martha":{"filter":{"term":{"user":"martha"}}}}},"mongoid_articles":{"aliases":{}},"index_C":{"aliases":{"alias_martha":{"filter":{"term":{"user":"martha"}}}}}}|), 200 ).at_least_once
        end

        should "add indices to alias" do
          Configuration.client.expects(:post).with do |url, json|
            # puts json
            MultiJson.decode(json)['actions'].any? do |a|
              a['add']['index'] == 'index_A' &&
              a['add']['alias'] == 'alias_martha'
              end
          end.returns(mock_response('{}'), 200)

          a = Alias.find('alias_martha')
          a.indices.push 'index_A'
          a.save
        end

        should "remove indices from alias" do
          Configuration.client.expects(:post).with do |url, json|
            # puts json
            MultiJson.decode(json)['actions'].any? do |a|
                a['remove'] &&
                a['remove']['index'] == 'index_A' &&
                a['remove']['alias'] == 'alias_martha'
              end
          end.returns(mock_response('{}'), 200)

          a = Alias.find('alias_martha')
          a.indices.delete 'index_A'
          a.save
        end

        should "change alias configuration" do
          Configuration.client.expects(:post).with do |url, json|
            # puts json
            MultiJson.decode(json)['actions'].all? { |a| a['add']['routing'] == 'martha' }
          end.returns(mock_response('{}'), 200)

          a = Alias.find('alias_martha')
          a.routing('martha')
          a.save
        end

      end

      context "saving" do

        should "send data to Elasticsearch" do
          Configuration.client.expects(:post).with do |url, json|
            url  == "#{Configuration.url}/_aliases" &&
            json =~ /"index":"index_2012_05"/ &&
            json =~ /"alias":"index_current"/
          end.returns(mock_response('{}'), 200)

          @alias = Alias.new :name => 'index_current', :index => 'index_2012_05'
          @alias.save
        end

        should "log request" do
          Tire.configure { logger '/dev/null' }

          Configuration.client.expects(:post)
          Configuration.logger.expects(:log_request)
          Alias.new( :name => 'index_current', :index => 'index_2012_05' ).save
        end

      end

      context "finding" do
        setup do
          Configuration.client.expects(:get).with do |url, json|
              url  == "#{Configuration.url}/_aliases"
            end.returns( mock_response(                               %q|{"index_A":{"aliases":{}},"index_B":{"aliases":{"alias_john":{"filter":{"term":{"user":"john"}}},"alias_martha":{"filter":{"term":{"user":"martha"}}}}},"index_C":{"aliases":{"alias_martha":{"filter":{"term":{"user":"martha"}}}}}}|), 200 )
        end

        should "find all aliases" do
          aliases = Alias.all
          # p aliases
          assert_equal 2, aliases.size
          assert_equal ['index_B', 'index_C'], aliases.select { |a| a.name == 'alias_martha'}.first.indices.to_a.sort
        end

        should "find aliases for a specific index" do
          Configuration.client.unstub(:get)
          Configuration.client.expects(:get).with do |url, json|
              url  == "#{Configuration.url}/index_C/_aliases"
            end.returns( mock_response(                               %q|{"index_C":{"aliases":{"alias_martha":{"filter":{"term":{"user":"martha"}}}}}}|), 200 )

          aliases = Alias.all('index_C')
          # p aliases
          assert_equal 1, aliases.size
          assert_equal ['index_C'], aliases.last.indices.to_a
        end

        should "find an alias" do
          a = Alias.find('alias_martha')
          assert_instance_of Alias, a
          assert_equal ['index_B', 'index_C'], a.indices.to_a.sort
        end

        should "find an alias and configure it with a block" do
          a = Alias.find('alias_martha') do |a|
                a.indices.delete 'index_A'
                a.indices.add    'index_D'
              end

          assert_equal ['index_B', 'index_C', 'index_D'], a.indices.to_a.sort
        end

      end

      context "creating" do
        setup do
          Configuration.client.expects(:post).with do |url, json|
            url  == "#{Configuration.url}/_aliases" &&
            json =~ /"index":"index_2012_05"/ &&
            json =~ /"alias":"index_current"/
          end.returns(mock_response('{}'), 200)
        end

        should "create the alias" do
          Alias.create :name => 'index_current', :index => 'index_2012_05'
        end

        should "create the alias with a block" do
          Alias.create :name => 'index_current' do
            index 'index_2012_05'
          end
        end

      end

    end

    context "IndexCollection" do

      should "be intialized with an array or arguments list" do
        c1 = Alias::IndexCollection.new ['1', '2', '3']
        c2 = Alias::IndexCollection.new '1', '2', '3'
        assert_equal c1.to_a, c2.to_a
      end

      should "be iterable" do
        c = Alias::IndexCollection.new '1', '2', '3'
        assert_respond_to c, :each
        assert_respond_to c, :size
        assert_equal [1, 2, 3], c.map(&:to_i)
      end

      should "allow adding values" do
        c = Alias::IndexCollection.new '1', '2'
        c.add '3'
        assert_equal 3, c.size
        assert_equal ['1', '2', '3'], c.add_indices
        assert_equal [],              c.remove_indices
      end

      should "allow removing values" do
        c = Alias::IndexCollection.new '1', '2'
        c.remove '1'
        assert_equal 1, c.size
        assert_equal ['2'], c.add_indices
        assert_equal ['1'], c.remove_indices
      end

      should "clear everything" do
        c = Alias::IndexCollection.new '1', '2'
        c.clear
        assert_equal 0, c.size
        assert_equal [], c.add_indices
        assert_equal ['1', '2'], c.remove_indices
      end

      should "respond to empty" do
        c = Alias::IndexCollection.new
        assert c.empty?, "#{c.inspect} should be empty"
      end

      should "remove values with a block" do
        c = Alias::IndexCollection.new '1', '2', '3'

        c.delete_if { |a| a.to_i > 1 }
        assert_equal 1, c.size
        assert_equal ['1'],      c.add_indices
        assert_equal ['2', '3'], c.remove_indices
      end

    end

    context "aliases with index and search routing values" do
      setup do
        json =<<-JSON
{
    "index_A": {
        "aliases": {}
    },
    "index_B": {
        "aliases": {
            "alias_john": {
                "filter": {
                    "term": {
                        "user": "john"
                    }
                }
            },
            "alias_martha": {
                "filter": {
                    "term": {
                        "user": "martha"
                    }
                }
            }
        }
    },
    "index_C": {
        "aliases": {
            "alias_martha": {
                "filter": {
                    "term": {
                        "user": "martha"
                    }
                },
                "index_routing": "1",
                "search_routing": "2"
            }
        }
    }
}
        JSON
          Configuration.client.expects(:get).
                               returns( mock_response(json), 200).
                               at_least_once
      end

        should "find all aliases" do
          aliases = Alias.all
          # p aliases
          assert_equal 2, aliases.size
          assert_equal ['index_B', 'index_C'], aliases.select { |a| a.name == 'alias_martha'}.first.indices.to_a.sort
        end

        should "find an alias" do
          a = Alias.find('alias_martha')
          assert_instance_of Alias, a
          assert_equal ['index_B', 'index_C'], a.indices.to_a.sort
        end
    end

  end
end
