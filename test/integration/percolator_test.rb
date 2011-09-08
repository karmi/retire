require 'test_helper'

module Tire

  class PercolatorIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Percolator" do
      setup do
        delete_registered_queries
        @index = Tire.index('percolator-test')
        @index.create
      end
      teardown do
        delete_registered_queries
        @index.delete
      end

      context "when registering a query" do
        should "register query as a Hash" do
          query = { :query => { :query_string => { :query => 'warning' } } }
          assert @index.register_percolator_query('alert', query)
          Tire.index('_percolator').refresh

          percolator = Configuration.client.get("#{Configuration.url}/_percolator/percolator-test/alert")
          assert percolator
        end

        should "register query as block" do
          assert @index.register_percolator_query('alert') { string 'warning' }
          Tire.index('_percolator').refresh

          percolator = Configuration.client.get("#{Configuration.url}/_percolator/percolator-test/alert")
          assert percolator
        end

        should "unregister a query" do
          query = { :query => { :query_string => { :query => 'warning' } } }
          assert @index.register_percolator_query('alert', query)
          Tire.index('_percolator').refresh
          assert Configuration.client.get("#{Configuration.url}/_percolator/percolator-test/alert")

          assert @index.unregister_percolator_query('alert')
          Tire.index('_percolator').refresh

          assert Configuration.client.get("#{Configuration.url}/_percolator/percolator-test/alert").code != 200
        end

      end

      context "when percolating a document" do
        setup do
          @index.register_percolator_query('alert') { string 'warning' }
          @index.register_percolator_query('gantz') { string '"y u no match"' }
          @index.register_percolator_query('weather', :tags => ['weather']) { string 'severe' }
          Tire.index('_percolator').refresh
        end

        should "return an empty array when no query matches" do
          matches = @index.percolate :message => 'Situation normal'
          assert_equal [], matches
        end

        should "return an array of matching query names" do
          matches = @index.percolate :message => 'Severe weather warning'
          assert_equal ['alert','weather'], matches.sort
        end

        should "return an array of matching query names for specific percolated queries" do
          matches = @index.percolate(:message => 'Severe weather warning') { term :tags, 'weather' }
          assert_equal ['weather'], matches
        end
      end

      context "when storing document and percolating it" do
        setup do
          @index.register_percolator_query('alert') { string 'warning' }
          @index.register_percolator_query('gantz') { string '"y u no match"' }
          @index.register_percolator_query('weather', :tags => ['weather']) { string 'severe' }
          Tire.index('_percolator').refresh
        end

        should "return an empty array when no query matches" do
          response = @index.store( {:message => 'Situation normal'}, {:percolate => true} )
          assert_equal [], response['matches']
        end

        should "return an array of matching query names" do
          response = @index.store( {:message => 'Severe weather warning'}, {:percolate => true} )
          assert_equal ['alert','weather'], response['matches'].sort
        end

        should "return an array of matching query names for specific percolated queries" do
          response = @index.store( {:message => 'Severe weather warning'}, {:percolate => 'tags:weather'} )
          assert_equal ['weather'], response['matches']
        end
      end

    end

    private

    def delete_registered_queries
      Configuration.client.get("#{Configuration.url}/_percolator/percolator-test/alert") rescue nil
      Configuration.client.get("#{Configuration.url}/_percolator/percolator-test/gantz") rescue nil
      Configuration.client.get("#{Configuration.url}/_percolator/percolator-test/weather") rescue nil
    end

  end

end
