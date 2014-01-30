require 'test_helper'

module Tire

  class SuggestTest < Test::Unit::TestCase

    context "Suggest" do
      setup { Configuration.reset }

      should "be initialized with single index" do
        s = Suggest::Suggest.new('index') do 
          suggestion 'default-suggestion' do 
            text 'foo'
            completion 'bar'
          end
        end
        assert_match %r|/index/_suggest|, s.url
      end

      should "allow to suggest all indices by leaving index empty" do
        s = Suggest::Suggest.new do 
          suggestion 'default-suggestion' do 
            text 'foo'
            completion 'bar'
          end
        end
        assert_match %r|localhost:9200/_suggest|, s.url
      end

      should "return curl snippet for debugging" do
        s = Suggest::Suggest.new('index') do 
          suggestion 'default-suggestion' do 
            text 'foo'
            completion 'bar'
          end
        end
        assert_match %r|curl \-X GET 'http://localhost:9200/index/_suggest\?pretty' -d |, s.to_curl
        assert_match %r|\s*{\s*"default-suggestion"\s*:\s*{\s*"text"\s*:\s*"foo"\s*,\s*"completion"\s*:\s*{\s*"field"\s*:\s*"bar"\s*}\s*}\s*}\s*|, s.to_curl
      end

      should "return itself as a Hash" do
        s = Suggest::Suggest.new('index') do 
          suggestion 'default_suggestion' do 
            text 'foo'
            completion 'bar'
          end
        end
        assert_nothing_raised do
          assert_instance_of Hash,  s.to_hash
          assert_equal "foo", s.to_hash[:default_suggestion][:text]
        end
      end

      should "allow to pass options for completion queries" do
        s = Suggest::Suggest.new do
          suggestion 'default_suggestion' do
            text 'foo'
            completion 'bar', :fuzzy => true
          end
        end
        assert_equal true, s.to_hash[:default_suggestion][:completion][:fuzzy]
      end

      should "perform the suggest lazily" do
        response = mock_response '{"_shards": {"total": 5, "successful": 5, "failed": 0}, "default-suggestion": [{"text": "ssd", "offset": 0, "length": 10, "options": [] } ] }', 200
        Configuration.client.expects(:get).returns(response)
        Results::Suggestions.expects(:new).returns([])

        s = Suggest::Suggest.new('index') do 
          suggestion 'default-suggestion' do 
            text 'foo'
            completion 'bar'
          end
        end
        assert_not_nil s.results
        assert_not_nil s.response
        assert_not_nil s.json
      end

    end
  end
end
