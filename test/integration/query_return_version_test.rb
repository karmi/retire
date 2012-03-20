require 'test_helper'

module Tire

  class DslVersionIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "DSL Version" do

      setup do
        Tire.index 'articles-test-ids' do
          delete
          create

          store :id => 1, :title => 'One'
          store :id => 2, :title => 'Two'

          refresh
        end
      end

      teardown { Tire.index('articles-test-ids').delete }

      should "returns actual version (non-nil) value for records when 'version' is true" do
        s = Tire.search('articles-test-ids') do
          version true
          query { string 'One' }
        end

        assert_equal 1, s.results.count

        document = s.results.first
        assert_equal 'One', document.title
        assert_equal 1,     document._version.to_i

      end

      should "returns a nil version field when 'version' is false" do
        s = Tire.search('articles-test-ids') do
          version false
          query { string 'One' }
        end

        assert_equal 1, s.results.count

        document = s.results.first
        assert_equal 'One', document.title
        assert_nil   document._version

      end

      should "returns a nil version field when 'version' is not included" do
        s = Tire.search('articles-test-ids') do
          query { string 'One' }
        end

        assert_equal 1, s.results.count

        document = s.results.first
        assert_equal 'One', document.title
        assert_nil   document._version

      end

    end

  end

end

