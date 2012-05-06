require 'test_helper'

require 'active_support/core_ext/numeric'
require 'active_support/core_ext/date/calculations'

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
      
         assert_equal ['index-aliased'], @index.aliases.map(&:name)
       end
 
      should "retrieve the properties of an alias" do
        @index.add_alias 'index-aliased', :routing => '1'

        assert_equal '1', @index.aliases('index-aliased').search_routing
      end
    end

    context "In the 'sliding window' scenario" do

      setup do
        WINDOW_SIZE_IN_WEEKS = 4

        @indices = WINDOW_SIZE_IN_WEEKS.times.map { |number| "articles_#{number.weeks.ago.strftime('%Y-%m-%d')}" }

        @indices.each_with_index do |name,i|
          Tire.index(name) do
            delete
            create
            store   :title => "Document #{i}"
            refresh
          end
          Alias.new(:name => "articles_current") { |a| a.indices(name) and a.save }
        end
      end

      teardown do
        @indices.each { |index| Tire.index(index).delete }
      end

      should "add a new index to alias" do
        @indices << "articles_#{(WINDOW_SIZE_IN_WEEKS+1).weeks.ago.strftime('%Y-%m-%d')}"
        Tire.index(@indices.last).create
        Alias.new(:name => "articles_current") { |a| a.index @indices.last and a.save }

        a = Alias.find("articles_current")
        assert_equal 5, a.indices.size
      end

      should "remove the stale index from the alias" do
        Alias.find("articles_current") do |a|
          # Remove all indices older then 2 weeks from the alias
          a.indices.delete_if do |i|
            Time.parse( i.gsub(/articles_/, '') ) < 2.weeks.ago rescue false
          end
          a.save
        end

        assert_equal 2, Alias.find("articles_current").indices.size
      end

      should "search within the alias" do
        Alias.find("articles_current") do |a|
          a.indices.clear and a.indices @indices[0..1] and a.save
        end

        assert_equal 4, Tire.search(@indices) { query {all} }.results.size
        assert_equal 2, Tire.search("articles_current") { query {all} }.results.size
      end

    end

  end

end
