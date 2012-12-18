require 'test_helper'

module Tire

  class MultiSearchIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Multi search" do
      # Tire.configure { logger STDERR }
      setup do
        Tire.index 'multi-search-test-1' do
          delete
          create
          store first_name: 'John', last_name: 'Smith',    age: 30, gender: 'male'
          store first_name: 'John', last_name: 'Smithson', age: 25, gender: 'male'
          store first_name: 'Mary', last_name: 'Smith',    age: 20, gender: 'female'
          refresh
        end
        Tire.index 'multi-search-test-2' do
          delete
          create
          store first_name: 'John', last_name: 'Milton', age: 35, gender: 'male'
          store first_name: 'Mary', last_name: 'Milson', age: 44, gender: 'female'
          store first_name: 'Mary', last_name: 'Reilly', age: 55, gender: 'female'
          refresh
        end
      end

      teardown do
        Tire.index('multi-search-test-1').delete
        Tire.index('multi-search-test-2').delete
      end

      should "return multiple results" do
        s = Tire.multi_search 'multi-search-test-1' do
          search :johns do
            query { match :_all, 'john' }
          end
          search :males do
            query { match :gender, 'male' }
          end
          search :facets, search_type: 'count' do
            facet('age') { statistical :age }
          end
        end

        assert_equal 3,    s.results.size

        assert_equal 2,    s.results[:johns].size
        assert_equal 2,    s.results[:males].size

        assert s.results[:facets].results.empty?, "Results not empty? #{s.results[:facets].results}"
        assert_equal 75.0, s.results[:facets].facets['age']['total']
      end

      should "mix named and numbered searches" do
        s = Tire.multi_search 'multi-search-test-1' do
          search(:johns) { query { match :_all, 'john' }  }
          search         { query { match :_all, 'mary' }  }
        end

        assert_equal 2, s.results.size

        assert_equal 2, s.results[:johns].size
        assert_equal 1, s.results[1].size
      end

      should "iterate over mixed searches" do
        s = Tire.multi_search 'multi-search-test-1' do
          search(:johns) { query { match :_all, 'john' }  }
          search         { query { match :_all, 'mary' }  }
        end

        assert_equal [:johns, 1], s.searches.names
        assert_equal [:johns, 1], s.results.to_hash.keys

        s.results.each_with_index do |results, i|
          assert_equal 2, results.size if i == 0
          assert_equal 1, results.size if i == 1
        end

        s.results.each_pair do |name, results|
          assert_equal 2, results.size if name == :johns
          assert_equal 1, results.size if name == 1
        end
      end

      should "return results from different indices" do
        s = Tire.multi_search do
          search( index: 'multi-search-test-1' ) { query { match :_all, 'john' }  }
          search( index: 'multi-search-test-2' ) { query { match :_all, 'john' }  }
        end

        assert_equal 2, s.results[0].size
        assert_equal 1, s.results[1].size
      end

      should "return error for failed searches" do
        s = Tire.multi_search 'multi-search-test-1' do
          search() { query { match :_all, 'john' }  }
          search() { query { string '[x' }  }
        end

        assert_equal 2, s.results[0].size
        assert          s.results[0].success?

        assert_equal 0, s.results[1].size
        assert          s.results[1].failure?
      end
    end

  end

end
