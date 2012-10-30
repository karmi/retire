require 'test_helper'

module Tire

  class MatchQueryIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Match query" do
      setup do
        Tire.index 'match-query-test' do
          delete
          create settings: { index: { number_of_shards: 1, number_of_replicas: 0 } },
                 mappings: {
                  document: { properties: {
                    last_name: { type: 'string', analyzer: 'english' },
                    age:       { type: 'integer' }
                  } }
                 }

          store first_name: 'John', last_name: 'Smith',    age: 30, gender: 'male'
          store first_name: 'John', last_name: 'Smithson', age: 25, gender: 'male'
          store first_name: 'Adam', last_name: 'Smith',    age: 75, gender: 'male'
          store first_name: 'Mary', last_name: 'John',     age: 30, gender: 'female'
          refresh
        end
      end

      teardown do
        Tire.index('match-query-test').delete
      end

      should "find documents by single field" do
        s = Tire.search 'match-query-test' do
          query do
            match :last_name, 'Smith'
          end
        end

        assert_equal 2, s.results.count
      end

      should "find document by multiple fields with multi_match" do
        s = Tire.search 'match-query-test' do
          query do
            match [:first_name, :last_name], 'John'
          end
        end

        assert_equal 3, s.results.count
      end

      should "find documents by prefix" do
        s = Tire.search 'match-query-test' do
          query do
            match :last_name, 'Smi', type: 'phrase_prefix'
          end
        end

        assert_equal 3, s.results.count
      end

      should "automatically create a boolean query when called repeatedly" do
        s = Tire.search 'match-query-test' do
          query do
            match [:first_name, :last_name], 'John'
            match :age, 30
            match :gender, 'male'
          end
          # puts to_curl
        end

        assert_equal 1, s.results.count
      end

    end

  end

end
