require 'test_helper'

module Tire

  class IndexMappingIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Default mapping" do
      teardown { Tire.index('mapped-index').delete; sleep 0.1 }

      should "create and return the default mapping" do

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
          create :mappings => { :article => { :properties => { :title => { :type => 'string', :boost => 2.0, :store => 'yes' } } } }
        end

        # p index.mapping    
        assert_equal 2.0,   index.mapping['article']['properties']['title']['boost'],  index.mapping.inspect
        assert_equal 'yes', index.mapping['article']['properties']['title']['store'],  index.mapping.inspect
    
      end
    end

    context "Put mapping" do
      setup{ Tire.index("mapped-index").create; sleep 1 }
      teardown{ Tire.index("mapped-index").delete; sleep 0.1 }

      should "update the mapping for a given type" do
        index = Tire.index("mapped-index")

        index.mapping("article", :properties => { :body => { :type => "string" } })
        assert_equal({ "type" => "string" }, index.mapping["article"]["properties"]["body"])

        index.mapping("article", :properties => { :title => { :type => "string" } })
        mapping = index.mapping
        assert_equal mapping["article"]["properties"]["body"], { "type" => "string" }
        assert_equal mapping["article"]["properties"]["title"], { "type" => "string" }
      end

      should "honor the ignore conflicts option" do
        index = Tire.index("mapped-index")

        index.mapping("article", :properties => { :body => { :type => "string" } })
        assert_equal({ "type" => "string" }, index.mapping["article"]["properties"]["body"])

        response = index.mapping("article", :properties => { :body => { :type => "integer" } })
        assert response["error"] =~ /^MergeMappingException/

        response = index.mapping("article", :ignore_conflicts => true, :properties => { :body => { :type => "integer" } })
        assert response["ok"]
      end

    end

  end

end
