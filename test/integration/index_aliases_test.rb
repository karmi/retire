require 'test_helper'

module Tire

  class IndexAliasesIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "With a filtered alias" do
      setup do

        @index = Tire.index 'index-original' do
          delete
          create
        end
        
      end

      teardown { Tire.index('index-original').delete }
      
       should "create the alias" do
         @index.add_alias 'index-aliased'
         assert_equal 1, @index.aliases.size
       end
      
       should "find only portion of documents in the filtered alias" do
         Tire.index 'index-original' do
           add_alias 'index-aliased', :filter => { :term => { :user => 'anne' } }
           store :title => 'Document 1', :user => 'anne'
           store :title => 'Document 2', :user => 'mary'
      
           refresh
         end
      
         assert_equal 2, Tire.search('index-original') { query { all } }.results.size
         assert_equal 1, Tire.search('index-aliased')  { query { all } }.results.size
       end
      
       should "remove the alias" do
         @index.add_alias 'index-aliased'
         assert_equal 1, @index.aliases.size
      
         @index.remove_alias 'index-aliased'
         assert_equal 0, @index.aliases.size
      
         assert_raise Tire::Search::SearchRequestFailed do
           Tire.search('index-aliased')  { query { all } }.results
         end
       end
      
       should "retrieve a list of aliases for an index" do
         @index.add_alias 'index-aliased'
      
         assert_equal ['index-aliased'], @index.aliases
       end
 
      should "retrieve the properties of an alias" do
        @index.add_alias 'index-aliased', :routing => '1'

        assert_equal(
          { 'index_routing'  => '1',
            'search_routing' => '1' },
          @index.aliases('index-aliased') )
      end
    end

  end

end
