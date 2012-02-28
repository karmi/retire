require 'test_helper'

module Tire

  class FilteredQueriesIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Filtered queries" do

      should "restrict the results" do
        # 2.json > Begins with "T" and is tagged "ruby"

        s = Tire.search('articles-test') do
          query do
            filtered do
              query { string 'title:T*' }
              filter :terms, :tags => ['ruby']
            end
          end
        end

        assert_equal 1, s.results.count
        assert_equal 'Two', s.results.first.title
      end

      should "restrict the results with multiple filters" do
        # 2.json > Is tagged "ruby" and has 250 words

        s = Tire.search('articles-test') do
          query do
            filtered do
              query { all }
              filter :and, { :terms => { :tags => ['ruby', 'python'] } },
                           { :range => { :words => { :from => '250', :to => '250' } } }
            end
          end
        end

        assert_equal 1, s.results.count
        assert_equal 'Two', s.results.first.title
      end

      context "boolean filter queries" do

        context "must" do

          should "apply both filters" do

            s = Tire.search('articles-test') do
              query do
                filtered do
                  query { all }
                  boolean do
                    must do
                      filter :terms, { :tags => ['ruby'] }
                      filter :terms, { :tags => ['python'] }
                    end
                  end
                end
              end
            end

            # assert_equal({}, s.to_hash)
            assert_equal 1, s.results.count

          end

        end

      end

    end

  end

end
