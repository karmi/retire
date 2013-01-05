require 'test_helper'

module Tire

  class DisMaxQueriesIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Dis Max queries" do
      setup do
        Tire.index 'dis_max_test' do
          delete
          create

          store title: "It's an Albino, Albino, Albino thing!", text: "Albino, albino, albino! Wanna know about albino? ..."
          store title: "Albino Vampire Monkey Attacks!",        text: "The night was just setting in when ..."
          store title: "Pinky Elephant",                        text: "An albino walks into a ZOO and ..."
          refresh
        end
      end

      teardown do
        Tire.index('dis_max_test').delete
      end

      should_eventually "boost matches in both fields" do
        dis_max = Tire.search 'dis_max_test' do
          query do
            dis_max do
              query { string "albino elephant", fields: ['title', 'text'] }
            end
          end
        end
        # p "DisMax:", dis_max.results.map(&:title)

        assert_equal 'Pinky Elephant', dis_max.results.first.title

        # NOTE: This gives exactly the same result as a boolean query:
        # boolean = Tire.search 'dis_max_test' do
        #   query do
        #     boolean do
        #       should { string "albino",   fields: ['title', 'text'] }
        #       should { string "elephant", fields: ['title', 'text'] }
        #     end
        #   end
        # end
        # p "Boolean:", boolean.results.map(&:title)
      end

      should "allow to set multiple queries" do
        s = Tire.search('articles-test') do
          query do
            dis_max do
              query { term :tags, 'ruby' }
              query { term :tags, 'python' }
            end
          end
        end

        assert_equal 2, s.results.size
        assert_equal 'Two', s.results[0].title
        assert_equal 'One', s.results[1].title
      end

    end

  end

end
