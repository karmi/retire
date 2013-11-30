require 'test_helper'

module Tire

  class SuggestIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context 'Search Suggest' do

      should 'add suggestions field to the results using the term suggester' do
        # Tire::Configuration.logger STDERR, :level => 'debug'
        s = Tire.search('articles-test') do
          suggest :term_suggest1 do
            text 'thrree'
            term :title
          end
        end

        assert_equal 1, s.results.suggestions.size
        assert_equal 'three', s.results.suggestions.texts.first
      end

      should 'add suggestions field to the results using the phrase suggester' do
        # Tire::Configuration.logger STDERR, :level => 'debug'
        s = Tire.search('articles-test') do
          suggest :phrase_suggest1 do
            text 'thrree'
            phrase :title
          end
        end

        assert_equal 1, s.results.suggestions.size
        assert_equal 'three', s.results.suggestions.texts.first
      end

    end

    context 'Standalone term and phrase suggest' do

      should 'return term suggestions when used with standalone api' do
        # Tire::Configuration.logger STDERR, :level => 'debug'
        s = Tire.suggest('articles-test') do
          suggestion :term_suggest do
            text 'thrree'
            term :title
          end
        end

        assert_equal 1, s.results.texts.size
        assert_equal 'three', s.results.texts.first
      end

      should 'return phrase suggestions when used with standalone api' do
        # Tire::Configuration.logger STDERR, :level => 'debug'
        s = Tire.suggest('articles-test') do
          suggestion :prhase_suggest do
            text 'thrree'
            phrase :title
          end
        end

        assert_equal 1, s.results.texts.size
        assert_equal 'three', s.results.texts.first
      end

    end

    context 'Standalone suggest' do
      setup do
        Tire.index('suggest-test') do
          delete
          create :mappings => {
              :article => {
                  :properties => {
                      :title => {:type => 'string', :analyzer => 'simple'},
                      :title_suggest => {:type => 'completion', :analyzer => 'simple'},
                  }
              }
          }
          import([
                     {:id => '1', :type => 'article', :title => 'one', :title_suggest => 'one'},
                     # this document has multiple inputs for completion field and a specified output
                     {:id => '2', :type => 'article', :title => 'two', :title_suggest => {:input => %w(two dos due), :output => 'Two[2]'}},
                     {:id => '3', :type => 'article', :title => 'three', :title_suggest => 'three'}
                 ])
          refresh
        end
      end

      teardown do
        Tire.index('suggest-test') { delete }
      end

      should 'return completion suggestions when used with standalone api' do
        # Tire::Configuration.logger STDERR, :level => 'debug'
        s = Tire.suggest('suggest-test') do
          suggestion 'complete' do
            text 't'
            completion 'title_suggest'
          end
        end

        assert_equal 2, s.results.texts.size
        assert_equal %w(Two[2] three), s.results.texts
      end

      should 'allow multiple completion requests in the same request' do
        # Tire::Configuration.logger STDERR, :level => 'debug'
        s = Tire.suggest('suggest-test') do
          multi do
            suggestion 'foo' do
              text 'o'
              completion 'title_suggest'
            end
            suggestion 'bar' do
              text 'd'
              completion 'title_suggest'
            end
          end
        end

        assert_equal 2, s.results.size
        assert_equal %w(one), s.results.texts(:foo)
        assert_equal %w(Two[2]), s.results.texts(:bar)
      end

    end
  end
end