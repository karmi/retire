require 'test_helper'
require File.expand_path('../../models/mongoid_models', __FILE__)

begin
  require "mongo"
  Mongo::Connection.new("localhost", 27017)

  ENV["MONGODB_IS_AVAILABLE"] = 'true'
rescue Mongo::ConnectionFailure => e
  ENV["MONGODB_IS_AVAILABLE"] = nil
end

if ENV["MONGODB_IS_AVAILABLE"]
  module Tire

    class MongoidSearchableIntegrationTest < Test::Unit::TestCase
      include Test::Integration

      def setup
        super
        Mongoid.configure do |config|
          config.master = Mongo::Connection.new.db("tire_mongoid_integration_test")
        end
      end

      context "Mongoid integration" do

        setup    do
          MongoidArticle.destroy_all
          Tire.index('mongoid_articles').delete

          load File.expand_path('../../models/mongoid_models.rb', __FILE__)
        end
        teardown do
          MongoidArticle.destroy_all
          Tire.index('mongoid_articles').delete
        end

        should "configure mapping" do
          assert_equal 'snowball', MongoidArticle.mapping[:title][:analyzer]
          assert_equal 10, MongoidArticle.mapping[:title][:boost]

          assert_equal 'snowball', MongoidArticle.tire.index.mapping['mongoid_article']['properties']['title']['analyzer']
        end

        should "save document into index on save and find it" do
          a = MongoidArticle.new :title => 'Test'
          a.save!
          id = a.id

          a.index.refresh

          results = MongoidArticle.tire.search 'test'

          assert       results.any?
          assert_equal 1, results.count

          assert_instance_of Results::Item, results.first
          assert_not_nil results.first.id
          assert_equal   id.to_s, results.first.id.to_s
          assert         results.first.persisted?, "Record should be persisted"
          assert_not_nil results.first._score
          assert_equal   'Test', results.first.title
        end

        context "with eager loading" do
          setup do
            MongoidArticle.destroy_all

            @first_article  = MongoidArticle.create! :title => "Test 1"
            @second_article = MongoidArticle.create! :title => "Test 2"
            @third_article  = MongoidArticle.create! :title => "Test 3"
            @fourth_article = MongoidArticle.create! :title => "Test 4"
            @fifth_article  = MongoidArticle.create! :title => "Test 5"

            MongoidArticle.tire.index.refresh
          end

          should "load records on query search" do
            results = MongoidArticle.tire.search '"Test 1"', :load => true

            assert       results.any?
            assert_equal MongoidArticle.all.first, results.first
          end

          should "load records on block search" do
            results = MongoidArticle.tire.search :load => true do
              query { string '"Test 1"' }
            end

            assert_equal MongoidArticle.all.first, results.first
          end

          should "load records with options on query search" do
            assert_equal MongoidArticle.find([@first_article[:_id]], :include => 'comments').first,
            MongoidArticle.tire.search('"Test 1"',
                                  :load => { :include => 'comments' }).results.first
          end

          should "return empty collection for nonmatching query" do
            assert_nothing_raised do
              results = MongoidArticle.tire.search :load => true do
                query { string '"Hic Sunt Leones"' }
              end
              assert_equal 0, results.size
              assert !results.any?
            end
          end
        end

        should "remove document from index on destroy" do
          a = MongoidArticle.new :title => 'Test remove...'
          a.save!
          assert_equal 1, MongoidArticle.count

          a.destroy
          assert_equal 0, MongoidArticle.all.size

          a.index.refresh
          results = MongoidArticle.tire.search 'test'
          assert_equal 0, results.count
        end

        should "return documents with scores" do
          MongoidArticle.create! :title => 'foo'
          MongoidArticle.create! :title => 'bar'

          MongoidArticle.tire.index.refresh
          results = MongoidArticle.tire.search 'foo OR bar^100'
          assert_equal 2, results.count

          assert_equal 'bar', results.first.title
        end

        context "with pagination" do
          setup do
            1.upto(9) { |number| MongoidArticle.create :title => "Test#{number}" }
            MongoidArticle.tire.index.refresh
          end

          context "and parameter searches" do

            should "find first page with five results" do
              results = MongoidArticle.tire.search 'test*', :sort => 'title', :per_page => 5, :page => 1
              assert_equal 5, results.size

              assert_equal 2, results.total_pages
              assert_equal 1, results.current_page
              assert_equal nil, results.previous_page
              assert_equal 2, results.next_page

              assert_equal 'Test1', results.first.title
            end

            should "find next page with five results" do
              results = MongoidArticle.tire.search 'test*', :sort => 'title', :per_page => 5, :page => 2
              assert_equal 4, results.size

              assert_equal 2, results.total_pages
              assert_equal 2, results.current_page
              assert_equal 1, results.previous_page
              assert_equal nil, results.next_page

              assert_equal 'Test6', results.first.title
            end

            should "find not find missing page" do
              results = MongoidArticle.tire.search 'test*', :sort => 'title', :per_page => 5, :page => 3
              assert_equal 0, results.size

              assert_equal 2, results.total_pages
              assert_equal 3, results.current_page
              assert_equal 2, results.previous_page
              assert_equal nil, results.next_page

              assert_nil results.first
            end

          end

          context "and block searches" do
            setup { @q = 'test*' }

            should "find first page with five results" do
              results = MongoidArticle.tire.search do |search|
                search.query { |query| query.string @q }
                search.sort  { by :title }
                search.from 0
                search.size 5
              end
              assert_equal 5, results.size

              assert_equal 2, results.total_pages
              assert_equal 1, results.current_page
              assert_equal nil, results.previous_page
              assert_equal 2, results.next_page

              assert_equal 'Test1', results.first.title
            end

            should "find next page with five results" do
              results = MongoidArticle.tire.search do |search|
                search.query { |query| query.string @q }
                search.sort  { by :title }
                search.from 5
                search.size 5
              end
              assert_equal 4, results.size

              assert_equal 2, results.total_pages
              assert_equal 2, results.current_page
              assert_equal 1, results.previous_page
              assert_equal nil, results.next_page

              assert_equal 'Test6', results.first.title
            end

            should "not find a missing page" do
              results = MongoidArticle.tire.search do |search|
                search.query { |query| query.string @q }
                search.sort  { by :title }
                search.from 10
                search.size 5
              end
              assert_equal 0, results.size

              assert_equal 2, results.total_pages
              assert_equal 3, results.current_page
              assert_equal 2, results.previous_page
              assert_equal nil, results.next_page

              assert_nil results.first
            end

          end

        end

        context "with proxy" do

          should "allow access to Tire instance methods" do
            a = MongoidClassWithTireMethods.create :title => 'One'
            assert_equal "THIS IS MY INDEX!", a.index
            assert_instance_of Tire::Index, a.tire.index
            assert a.tire.index.exists?, "Index should exist"
          end

          should "allow access to Tire class methods" do
            class ::MongoidClassWithTireMethods
              include Mongoid::Document
              def self.search(*)
                "THIS IS MY SEARCH!"
              end
            end

            MongoidClassWithTireMethods.create :title => 'One'
            MongoidClassWithTireMethods.tire.index.refresh

            assert_equal "THIS IS MY SEARCH!", MongoidClassWithTireMethods.search

            results = MongoidClassWithTireMethods.tire.search 'one'

            assert_equal 'One', results.first.title
          end

        end

        context "within Rails" do

          setup do
            module ::Rails; end

            a = MongoidArticle.new :title => 'Test'
            c = a.comments.build :author => 'fool', :body => 'Works!'
            s = a.stats.build    :pageviews  => 12, :period => '2011-08'
            a.save!
            c.save!
            s.save!
            @id = a.id.to_s

            a.index.refresh
            @item = MongoidArticle.tire.search('test').first
          end

          should "have access to indexed properties" do
            assert_equal 'Test', @item.title
            assert_equal 'fool', @item.comments.first.author
            assert_equal 12,     @item.stats.first.pageviews
          end

          should "load the underlying models" do
            assert_instance_of Results::Item, @item
            assert_instance_of MongoidArticle, @item.load
            assert_equal      'Test', @item.load.title

            assert_instance_of Results::Item, @item.comments.first
            assert_instance_of MongoidComment, @item.comments.first.load
            assert_equal      'fool', @item.comments.first.load.author
          end

          should "load the underlying model with options" do
            assert_equal MongoidArticle.find(@id), @item.load(:include => 'comments')
          end

        end
      end
    end
  end
end
