require 'test_helper'

module Tire

  class IndexUpdateDocumentIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Updating a document" do

      setup do
        Tire.index 'articles-with-tags' do
          delete
          create

          store :type => 'article', :id => 1, :title => 'One',   :tags => ['foo'],        :views => 0
          store :type => 'article', :id => 2, :title => 'Two',   :tags => ['foo', 'bar'], :views => 10
          store :type => 'article', :id => 3, :title => 'Three', :tags => ['foobar']

          refresh
        end
      end

      teardown { Tire.index('articles-with-tags').delete }

      should "increment a counter" do
        Tire.index('articles-with-tags') { update( 'article', '1', {:script => "ctx._source.views += 1"}, :refresh => true) }

        document = Tire.search('articles-with-tags') { query { string 'title:one' } }.results.first
        assert_equal 1, document.views, document.inspect

        Tire.index('articles-with-tags') { update( 'article', '2', {:script => "ctx._source.views += 1"}, :refresh => true) }

        document = Tire.search('articles-with-tags') { query { string 'title:two' } }.results.first
        assert_equal 11, document.views, document.inspect
      end

      should "add a tag to document" do
        Tire.index('articles-with-tags') do
          update 'article', '1', {
              :script => "ctx._source.tags += tag",
              :params => { :tag => 'new' }
            },
            {
              :refresh => true
            }
        end

        document = Tire.search('articles-with-tags') { query { string 'title:one' } }.results.first
        assert_equal ['foo', 'new'], document.tags, document.inspect
      end

      should "remove a tag from document" do
        Tire.index('articles-with-tags') do
          update 'article', '1', {
              :script => "ctx._source.tags = tags",
              :params => { :tags => [] }
            }, {
              :refresh => true
            }
        end

        document = Tire.index('articles-with-tags').retrieve 'article', '1'
        assert_equal [], document.tags, document.inspect
      end

      should "remove the entire document if specific condition is met" do
        Tire.index('articles-with-tags') do
          # Remove document when it contains tag 'foobar'
          update 'article', '3', {
              :script => "ctx._source.tags.contains(tag) ? ctx.op = 'delete' : 'none'",
              :params => { :tag => 'foobar' }
            }, {
              :refresh => true
            }
        end

        assert_nil Tire.index('articles-with-tags').retrieve 'article', '3'
      end

      should "pass the operation parameters to the API" do
        Tire.index('articles-with-tags').update 'article', '2', { :script => "ctx._source.tags += tag",
                                                                  :params => { :tag => 'new' }
                                                                },
                                                                {
                                                                  :refresh => true
                                                                }

        document = Tire.search('articles-with-tags') { query { string 'title:two' } }.results.first
        assert_equal 3, document.tags.size, document.inspect
      end

      should "update the document with a partial one" do
        Tire.index('articles-with-tags') do
          update( 'article', '1', {:doc => { :title => 'One UPDATED' }}, :refresh => true )
        end

        document = Tire.search('articles-with-tags') { query { string 'title:one' } }.results.first
        assert_equal 'One UPDATED', document.title, document.inspect
      end

      should "access variables from the outer scope" do
        $t = self

        class Updater
          @tags = ['foo', 'bar', 'baz']

          def self.perform_update!
            $t.assert_not_nil @tags

            Tire.index('articles-with-tags') do |index|
              $t.assert_not_nil @tags

              index.update 'article', '3', {
                  :script => "ctx._source.tags = tags",
                  :params => { :tags => @tags }
                }, {
                  :refresh => true
                }
            end
          end
        end

        Updater.perform_update!

        document = Tire.search('articles-with-tags') { query { string 'title:three' } }.results.first
        assert_equal 3, document.tags.size, document.inspect
      end

    end
  end
end
