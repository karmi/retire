require 'test_helper'

module Tire
  class MultiSearchTest < Test::Unit::TestCase

    context "Multi::Search" do
      setup { Configuration.reset }

      should "be initialized with index" do
        @search = Tire::Search::Multi::Search.new 'foo'
        assert_equal ['foo'], @search.indices
      end

      context "search definition" do
        setup do
          @search_definitions = Tire::Search::Multi::SearchDefinitions.new
        end

        should "be enumerable" do
          assert_respond_to @search_definitions, :each
          assert_respond_to @search_definitions, :size
        end

        should "allow to add definition" do
          @search_definitions << { :name => 'foo', :search => { 'query' => 'bar' } }
          assert_equal 1, @search_definitions.size
        end

        should "return definition" do
          @search_definitions << { :name => 'foo', :search => { 'query' => 'bar' } }
          assert_equal 'bar', @search_definitions['foo']['query']
        end

        should "have names" do
          @search_definitions << { :name => 'foo', :search => { 'query' => 'bar' } }
          assert_equal ['foo'], @search_definitions.names
        end
      end

      context "search results" do
        setup do
          @search_definitions = Tire::Search::Multi::SearchDefinitions.new
          @search_definitions << { :name => 'foo', :search => Tire::Search::Search.new }
          @responses          = [{ 'hits' => { 'hits' => [{'_id' => 1},
                                                          {'_id' => 2},
                                                          {'_id' => 3}] }
                                }]

          @results = Tire::Search::Multi::Results.new @search_definitions, @responses
        end

        should "be enumerable" do
          assert_respond_to @results, :each
          assert_respond_to @results, :each_pair
          assert_respond_to @results, :each_with_index
          assert_respond_to @results, :size
        end

        should "return named results" do
          assert_instance_of Tire::Results::Collection, @results['foo']
          assert_equal 1, @results['foo'].first.id
        end

        should "return nil for incorrect index" do
          assert_nil @results['moo']
          assert_nil @results[999]
        end

        should "iterate over results" do
          @results.each do |results|
            assert_instance_of Tire::Results::Collection, results
          end
        end

        should "iterate over named results" do
          @results.each_pair do |name, results|
            assert_equal       'foo', name
            assert_instance_of Tire::Results::Collection, results
          end
        end

        should "be serializable to Hash" do
          assert_instance_of Tire::Results::Collection, @results.to_hash['foo']
        end

        should "pass search options to collection" do
          @search_definitions = Tire::Search::Multi::SearchDefinitions.new
          @search_definitions << { :name => 'foo', :search => Tire::Search::Search.new(nil, :foo => 'bar') }
          @responses          = [{ 'hits' => { 'hits' => [{'_id' => 1}] } }]

          @results = Tire::Search::Multi::Results.new @search_definitions, @responses

          assert_equal 'bar', @results['foo'].options[:foo]
        end

        context "error responses" do
          setup do
            @search_definitions = Tire::Search::Multi::SearchDefinitions.new
            @search_definitions << { :name => 'foo', :search => Tire::Search::Search.new }
            @search_definitions << { :name => 'xoo', :search => Tire::Search::Search.new }
            @responses          = [{ 'hits' => { 'hits' => [{'_id' => 1},
                                                            {'_id' => 2},
                                                            {'_id' => 3}] }
                                   },
                                   {'error' => 'SearchPhaseExecutionException ...'}
                                  ]

            @results = Tire::Search::Multi::Results.new @search_definitions, @responses
          end

          should "return success/failure state" do
            assert_equal true, @results['foo'].success?
            assert_equal 3,    @results['foo'].size
            assert_equal true, @results['xoo'].failure?
          end
        end
      end

      context "URL" do

        should "have no index and type by default" do
          @search = Tire::Search::Multi::Search.new
          assert_equal '/_msearch', @search.path
        end

        should "have an index" do
          @search = Tire::Search::Multi::Search.new 'foo'
          assert_equal '/foo/_msearch', @search.path
        end

        should "have multiple indices" do
          @search = Tire::Search::Multi::Search.new ['foo', 'bar']
          assert_equal '/foo,bar/_msearch', @search.path
        end

        should "have index and type" do
          @search = Tire::Search::Multi::Search.new 'foo', :type => 'bar'
          assert_equal '/foo/bar/_msearch', @search.path
        end

        should "have index and multiple types" do
          @search = Tire::Search::Multi::Search.new 'foo', :type => ['bar', 'bam']
          assert_equal '/foo/bar,bam/_msearch', @search.path
        end

        should "contain host" do
          @search = Tire::Search::Multi::Search.new
          assert_equal 'http://localhost:9200/_msearch', @search.url
        end

      end

      context "URL params" do

        should "be empty when no params passed" do
          @search = Tire::Search::Multi::Search.new 'foo'
          assert_equal '', @search.params
        end

        should "serialize parameters" do
          @search = Tire::Search::Multi::Search.new 'foo', :search_type => 'count'
          assert_equal '?search_type=count', @search.params
        end

      end

      context "search request" do
        setup do
          @search = Tire::Search::Multi::Search.new
        end

        should "have a collection of searches" do
          @search.search :one
          assert_instance_of Tire::Search::Multi::SearchDefinitions, @search.searches
        end

        should "be initialized with name" do
          @search.search :one
          assert_instance_of Tire::Search::Search, @search.searches[:one]
        end

        should "be initialized with options" do
          @search.search :foo => 'bar'
          assert_equal 'bar', @search.searches[0].options[:foo]
        end

        should "be initialized with name and options" do
          @search.search :one, :foo => 'bar'
          assert_instance_of Tire::Search::Search, @search.searches[:one]
          assert_equal 'bar', @search.searches[:one].options[:foo]
          assert_equal 'bar', @search.searches(:one).options[:foo]
        end

        should "pass the index name and options to the search object" do
          @search.search :index => 'foo', :type => 'bar'
          assert_equal ['foo'], @search.searches[0].indices
          assert_equal ['bar'], @search.searches[0].types
          assert_equal ['foo'], @search.searches(0).indices
        end

        should "pass options to Search object" do
          @search.search :search_type => 'count'
          assert_equal 'count', @search.searches[0].options[:search_type]
        end

      end

      context "payload" do

        should "serialize search payload header and body as Array" do
          @search = Tire::Search::Multi::Search.new do
            search :index => 'foo' do
              query { all }
              size 100
            end
          end

          assert_equal 1, @search.searches.size
          assert_equal 2, @search.to_array.size

          assert_equal( 'foo', @search.to_array[0][:index] )
          assert_equal( {:match_all => {}}, @search.to_array[1][:query] )
          assert_equal( 100,   @search.to_array[1][:size] )
        end

        should "serialize search payload header and body for multiple searches" do
          @search = Tire::Search::Multi::Search.new do
            search(:index => 'foo') { query { all } }
            search(:index => 'ooo') { query { term :foo, 'bar' } }
          end

          assert_equal 2, @search.searches.size
          assert_equal 4, @search.to_array.size

          assert_equal 'foo', @search.to_array[0][:index]
          assert_equal 'ooo', @search.to_array[2][:index]
          assert_equal 'match_all', @search.to_array[1][:query].keys.first.to_s
          assert_equal 'term',      @search.to_array[3][:query].keys.first.to_s
        end

        should "serialize search parameters" do
          @search = Tire::Search::Multi::Search.new do
            search(:search_type => 'count') { query { all } }
          end

          assert_equal 'count', @search.to_array[0][:search_type]
        end

        should "serialize search payload as a string" do
          @search = Tire::Search::Multi::Search.new do
            search(:index => 'foo') { query { all } }
          end

          assert_equal 2, @search.to_payload.split("\n").size
        end

        should "end with a new line" do
          @search = Tire::Search::Multi::Search.new { search(:index => 'foo') { query { all } } }
          assert_match /.*\n$/, @search.to_payload
        end

        should "leave header empty when no index is passed" do
          @search = Tire::Search::Multi::Search.new do
            search() { query { all } }
          end

          assert_equal( {}, @search.to_array.first )
        end

      end

      context "perform" do
        setup do
          @search = Tire::Search::Multi::Search.new do
            search(:index => 'foo') do
              query { all }
              size 100
            end
          end
          @response = mock_response '{ "responses" : [{"took":1,"hits":{"total":0,"hits":[]}}] }', 200
        end

        should "perform the request" do
          Configuration.client.expects(:get).
            with do |url, payload|
              assert_equal 'http://localhost:9200/_msearch', url
              assert       payload.include?('match_all')
            end.
            returns(@response)
          @search.perform
        end

        should "log the request" do
          Configuration.client.expects(:get).returns(@response)
          @search.expects(:logged)
          @search.perform
        end

      end

    end

  end
end
