require 'test_helper'

module Tire

  class IndexMappingIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Default mapping" do
      teardown { Tire.index('mapped-index').delete; sleep 0.1 }

      should "create and return the default mapping as a Hash" do

        index = Tire.index 'mapped-index' do
          create
          store :type => :article, :title => 'One'
          refresh
          sleep 1
        end

        assert_equal 'string', index.mapping['article']['properties']['title']['type'],  index.mapping.inspect
        assert_nil             index.mapping['article']['properties']['title']['boost'], index.mapping.inspect
      end
    end

    context "Creating index with mapping" do
      teardown { Tire.index('mapped-index').delete; sleep 0.1 }

      should "create the specified mapping" do
        index = Tire.index 'mapped-index' do
          create mappings: {
            article: {
              _all: { enabled: false },
              properties: {
                title: { type: 'string', boost: 2.0, store: 'yes' }
              }
            }
          }
        end

        # p index.mapping
        assert_equal false, index.mapping['article']['_all']['enabled'],               index.mapping.inspect
        assert_equal 2.0,   index.mapping['article']['properties']['title']['boost'],  index.mapping.inspect
      end
    end

    context "Update mapping" do
      setup    { Tire.index("mapped-index").create; sleep 1   }
      teardown { Tire.index("mapped-index").delete; sleep 0.1 }

      should "update the mapping for type" do
        index = Tire.index("mapped-index")

        index.mapping "article", :properties => { :body => { :type => "string" } }
        assert_equal({ "type" => "string" }, index.mapping["article"]["properties"]["body"])

        assert index.mapping("article", :properties => { :title => { :type => "string" } })

        mapping = index.mapping

        # Verify return value
        assert mapping, index.response.inspect

        # Verify response
        assert_equal( { "type" => "string" }, mapping["article"]["properties"]["body"] )
        assert_equal( { "type" => "string" }, mapping["article"]["properties"]["title"] )
      end

      should "fail to update the mapping in an incompatible way" do
        index = Tire.index("mapped-index")

        # 1. Update initial index mapping
        assert index.mapping "article", properties: { body: { type: "string" } }
        assert_equal( { "type" => "string" }, index.mapping["article"]["properties"]["body"] )

        # 2. Attempt to update the mapping in incompatible way (change property type)
        mapping = index.mapping "article", :properties => { :body => { :type => "integer" } }

        # Verify return value
        assert !mapping, index.response.inspect
        #
        # Verify response
        assert_match /MergeMappingException/, index.response.body
      end

      should "honor the `ignore_conflicts` option" do
        index = Tire.index("mapped-index")

        # 1. Update initial index mapping
        assert index.mapping "article", properties: { body: { type: "string" } }
        assert_equal( { "type" => "string" }, index.mapping["article"]["properties"]["body"] )

        # 2. Attempt to update the mapping in incompatible way and ignore conflicts
        mapping = index.mapping "article", ignore_conflicts: true, properties: { body: { type: "integer" } }

        # Verify return value (true since we ignore conflicts)
        assert mapping, index.response.inspect
      end

    end

    context "Delete mapping" do
      setup    { Tire.index("mapped-index").create; sleep 1   }
      teardown { Tire.index("mapped-index").delete; sleep 0.1 }

      should "delete the mapping for type" do
        index = Tire.index("mapped-index")

        # 1. Update initial index mapping
        assert index.mapping 'article', properties: { body: { type: "string" } }

        assert index.delete_mapping 'article'
        assert index.mapping.empty?, index.response.inspect
      end
    end

  end

end
