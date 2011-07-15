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

  end

end
