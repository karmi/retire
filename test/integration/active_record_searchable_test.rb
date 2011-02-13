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

    context "ActiveRecord in :searchable mode" do

      setup    { Slingshot.index('active_record_articles').delete }
      teardown { Slingshot.index('active_record_articles').delete }

      should "save document into index on save and find it" do
        a = ActiveRecordArticle.new :title => 'Test'
        a.save!

        Slingshot.index('active_record_articles').refresh
        sleep(2) # Leave ES some breathing room here...
        results = ActiveRecordArticle.search 'test'
        
        assert_equal 1, results.count

        assert_instance_of ActiveRecordArticle, results.first
        assert_equal 'Test', results.first.title
      end

      should "remove document from index on destroy" do
        a = ActiveRecordArticle.new :title => 'Test'
        a.save!
        a.destroy

        Slingshot.index('active_record_articles').refresh
        results = ActiveRecordArticle.search 'test'
        
        assert_equal 0, results.count
      end

      should_eventually "retrieve sorted documents by IDs returned from search" do
        ActiveRecordArticle.create! :title => 'foo'
        ActiveRecordArticle.create! :title => 'bar'

        Slingshot.index('active_record_articles').refresh
        results = ActiveRecordArticle.search 'foo OR bar^100'
        p results
        assert_equal 2, results.count

        assert_equal 'bar', results.first.title
      end

    end

  end

end
