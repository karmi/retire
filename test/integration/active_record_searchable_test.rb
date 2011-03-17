require 'test_helper'

module Slingshot

  class ActiveRecordSearchableIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    def setup
      super
      File.delete fixtures_path.join('articles.db') rescue nil

      ActiveRecord::Base.establish_connection( :adapter => 'sqlite3', :database => fixtures_path.join('articles.db') )

      ActiveRecord::Migration.verbose = false
      ActiveRecord::Schema.define(:version => 1) do
        create_table :active_record_articles do |t|
          t.string   :title
          t.datetime :created_at, :default => 'NOW()'
        end
      end
    end

    def teardown
      super
      File.delete fixtures_path.join('articles.db') rescue nil
    end

    context "ActiveRecord integration" do

      setup    { Slingshot.index('active_record_articles').delete }
      teardown { Slingshot.index('active_record_articles').delete }

      should "save document into index on save and find it" do
        a = ActiveRecordArticle.new :title => 'Test'
        a.save!
        sleep(1) # Leave ES some breathing room here...
        a.index.refresh
        sleep(1) # Leave ES some breathing room here...
        results = ActiveRecordArticle.search 'test'

        assert_equal 1, results.count

        assert_instance_of ActiveRecordArticle, results.first
        assert_not_nil results.first.id
        assert_not_nil results.first.score
        assert_equal 'Test', results.first.title
      end

      should "remove document from index on destroy" do
        a = ActiveRecordArticle.new :title => 'Test'
        a.save!
        a.destroy

        a.index.refresh
        results = ActiveRecordArticle.search 'test'
        
        assert_equal 0, results.count
      end

      should "return documents with scores" do
        ActiveRecordArticle.create! :title => 'foo'
        ActiveRecordArticle.create! :title => 'bar'

        ActiveRecordArticle.index.refresh
        results = ActiveRecordArticle.search 'foo OR bar^100'
        assert_equal 2, results.count

        assert_equal 'bar', results.first.title
      end

      context "with pagination" do
        setup do
          1.upto(9) { |number| ActiveRecordArticle.create :title => "Test#{number}" }
          ActiveRecordArticle.index.refresh
        end

        context "and parameter searches" do

          should "find first page with five results" do
            results = ActiveRecordArticle.search 'test*', :sort => 'title', :per_page => 5, :page => 1
            assert_equal 5, results.size

            assert_equal 2, results.total_pages
            assert_equal 1, results.current_page
            assert_equal 0, results.previous_page
            assert_equal 2, results.next_page

            assert_equal 'Test1', results.first.title
          end

          should "find next page with five results" do
            results = ActiveRecordArticle.search 'test*', :sort => 'title', :per_page => 5, :page => 2
            assert_equal 4, results.size

            assert_equal 2, results.total_pages
            assert_equal 2, results.current_page
            assert_equal 1, results.previous_page
            assert_equal 3, results.next_page

            assert_equal 'Test6', results.first.title
          end

          should "find not find missing page" do
            results = ActiveRecordArticle.search 'test*', :sort => 'title', :per_page => 5, :page => 3
            assert_equal 0, results.size

            assert_equal 2, results.total_pages
            assert_equal 3, results.current_page
            assert_equal 2, results.previous_page
            assert_equal 4, results.next_page

            assert_nil results.first
          end

        end

        context "and block searches" do
          setup { @q = 'test*' }

          should "find first page with five results" do
            results = ActiveRecordArticle.search nil, :per_page => 5, :page => 1 do |search|
              search.query { |query| query.string @q }
              search.sort  { title }
              search.from 0
              search.size 5
            end
            assert_equal 5, results.size

            assert_equal 2, results.total_pages
            assert_equal 1, results.current_page
            assert_equal 0, results.previous_page
            assert_equal 2, results.next_page

            assert_equal 'Test1', results.first.title
          end

          should "find next page with five results" do
            results = ActiveRecordArticle.search nil, :per_page => 5, :page => 2 do |search|
              search.query { |query| query.string @q }
              search.sort  { title }
              search.from 5
              search.size 5
            end
            assert_equal 4, results.size

            assert_equal 2, results.total_pages
            assert_equal 2, results.current_page
            assert_equal 1, results.previous_page
            assert_equal 3, results.next_page

            assert_equal 'Test6', results.first.title
          end

          should "find not find missing page" do
            results = ActiveRecordArticle.search nil, :per_page => 5, :page => 3 do |search|
              search.query { |query| query.string @q }
              search.sort  { title }
              search.from 10
              search.size 5
            end
            assert_equal 0, results.size

            assert_equal 2, results.total_pages
            assert_equal 3, results.current_page
            assert_equal 2, results.previous_page
            assert_equal 4, results.next_page

            assert_nil results.first
          end

        end

      end

    end

  end

end
