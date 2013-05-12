require 'test_helper'

module Tire

  class ActiveRecordSearchableIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    def setup
      super
      ActiveRecord::Base.establish_connection( :adapter => 'sqlite3', :database => ":memory:" )

      ActiveRecord::Migration.verbose = false
      ActiveRecord::Schema.define(:version => 1) do
        create_table :active_record_articles do |t|
          t.string   :title
          t.datetime :created_at, :default => 'NOW()'
        end
        create_table :active_record_comments do |t|
          t.string     :author
          t.text       :body
          t.references :article
          t.timestamps
        end
        create_table :active_record_stats do |t|
          t.integer    :pageviews
          t.string     :period
          t.references :article
        end
        create_table :active_record_class_with_tire_methods do |t|
          t.string     :title
        end
        create_table :active_record_class_with_dynamic_index_names do |t|
          t.string     :title
        end
        create_table :active_record_model_with_percolations do |t|
          t.string   :title
          t.datetime :created_at, :default => 'NOW()'
        end
      end
    end

    context "ActiveRecord integration" do

      setup do
        ActiveRecordArticle.delete_all
        Tire.index('active_record_articles').delete

        load File.expand_path('../../models/active_record_models.rb', __FILE__)
      end

      teardown do
        ActiveRecordArticle.delete_all
        Tire.index('active_record_articles').delete
      end

      should "configure mapping" do
         assert_equal 'snowball', ActiveRecordArticle.mapping[:title][:analyzer]
         assert_equal 10, ActiveRecordArticle.mapping[:title][:boost]

         assert_equal 'snowball', ActiveRecordArticle.index.mapping['active_record_article']['properties']['title']['analyzer']
      end

      should "save document into index on save and find it" do
        a = ActiveRecordArticle.new :title => 'Test'
        a.save!
        id = a.id

        a.index.refresh

        results = ActiveRecordArticle.search 'test'

        assert       results.any?
        assert_equal 1, results.count

        assert_instance_of Results::Item, results.first
        assert_not_nil results.first.id
        assert_equal   id.to_s, results.first.id.to_s
        assert         results.first.persisted?, "Record should be persisted"
        assert_not_nil results.first._score
        assert_equal   'Test', results.first.title
      end

      should "remove document from index on destroy" do
        a = ActiveRecordArticle.new :title => 'Test remove...'
        a.save!
        assert_equal 1, ActiveRecordArticle.count

        a.destroy
        assert_equal 0, ActiveRecordArticle.all.size

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

      should "raise exception on invalid query" do
        ActiveRecordArticle.create! :title => 'Test'

        assert_raise Search::SearchRequestFailed do
          ActiveRecordArticle.search '[x'
        end
      end

      context "with eager loading" do
        setup do
          ActiveRecordArticle.destroy_all
          5.times { |n| ActiveRecordArticle.create! :title => "Test #{n+1}" }
          ActiveRecordArticle.index.refresh
        end

        should "load records on query search" do
          results = ActiveRecordArticle.search '"Test 1"', :load => true

          assert       results.any?
          assert_equal ActiveRecordArticle.find(1), results.first
        end

        should "load records on block search" do
          results = ActiveRecordArticle.search :load => true do
            query { string '"Test 1"' }
          end

          assert_equal ActiveRecordArticle.find(1), results.first
        end

        should "load single record" do
          a = ActiveRecordArticle.create :title => 'foo'
          a.save
          a.index.refresh

          results = ActiveRecordArticle.search load: true do
            query { string 'title:foo' }
          end

          assert_instance_of ActiveRecordArticle, results.first
          assert_equal 'foo', results.first.title
          assert_equal 3, a.length # Make sure we have the "real model"
        end

        should "load records with options on query search" do
          assert_equal ActiveRecordArticle.find(['1'], :include => 'comments').first,
                       ActiveRecordArticle.search('"Test 1"',
                                                  :load => { :include => 'comments' }).results.first
        end

        should "return empty collection for nonmatching query" do
          assert_nothing_raised do
            results = ActiveRecordArticle.search :load => true do
              query { string '"Hic Sunt Leones"' }
            end
            assert_equal 0, results.size
            assert ! results.any?
          end
        end

        should "iterate results with hits" do
          results = ActiveRecordArticle.search :load => true do
            query { string '"Test 1" OR "Test 2"' }
          end
          results.each_with_hit do |result, hit|
            assert_instance_of ActiveRecordArticle, result
            assert_instance_of Hash, hit
            assert_match /Test \d/, result.title
            assert_match /Test \d/, hit['_source']['title']
            assert hit['_score'] > 0
          end
        end

        should "provide access to highlighted fields in hit" do
          results = ActiveRecordArticle.search :load => true do
            query { string '"Test 1" OR "Test 2"' }
            highlight :title
          end
          results.each_with_hit do |result, hit|
            assert_equal 1, hit['highlight']['title'].size
          end
        end
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

            # WillPaginate
            #
            assert_equal 2, results.total_pages
            assert_equal 1, results.current_page
            assert_equal nil, results.previous_page
            assert_equal 2, results.next_page

            # Kaminari
            #
            assert_equal 5, results.limit_value
            assert_equal 9, results.total_count
            assert_equal 2, results.num_pages
            assert_equal 0, results.offset_value

            assert_equal 'Test1', results.first.title
          end

          should "find second page with four results" do
            results = ActiveRecordArticle.search 'test*', :sort => 'title', :per_page => 5, :page => 2
            assert_equal 4, results.size

            assert_equal 2, results.total_pages
            assert_equal 2, results.current_page
            assert_equal 1, results.previous_page
            assert_equal nil, results.next_page

            #kaminari
            assert_equal 5, results.limit_value
            assert_equal 9, results.total_count
            assert_equal 2, results.num_pages
            assert_equal 5, results.offset_value

            assert_equal 'Test6', results.first.title
          end

          should "find not find missing (third) page" do
            results = ActiveRecordArticle.search 'test*', :sort => 'title', :per_page => 5, :page => 3
            assert_equal 0, results.size

            assert_equal 2, results.total_pages
            assert_equal 3, results.current_page
            assert_equal 2, results.previous_page
            assert_equal nil, results.next_page

            #kaminari
            assert_equal 5, results.limit_value
            assert_equal 9, results.total_count
            assert_equal 2, results.num_pages
            assert_equal 10, results.offset_value

            assert_nil results.first
          end

          context "without an explicit per_page" do

            should "not find a missing (second) page" do
              results = ActiveRecordArticle.search 'test*', :sort => 'title', :page => 2
              assert_equal 0, results.size

              # WillPaginate
              #
              assert_equal 1, results.total_pages
              assert_equal 2, results.current_page
              assert_equal 1, results.previous_page
              assert_equal nil, results.next_page

              assert_nil results.first
            end

          end

        end

        context "and block searches" do
          setup { @q = 'test*' }

          context "with page/per_page" do

            should "find first page with five results" do
              results = ActiveRecordArticle.search :page => 1, :per_page => 5 do |search|
                search.query { |query| query.string @q }
                search.sort  { by :title }
              end
              assert_equal 5, results.size

              assert_equal 2, results.total_pages
              assert_equal 1, results.current_page
              assert_equal nil, results.previous_page
              assert_equal 2, results.next_page

              assert_equal 'Test1', results.first.title
            end

            should "find second page with four results" do
              results = ActiveRecordArticle.search :page => 2, :per_page => 5 do |search|
                search.query { |query| query.string @q }
                search.sort  { by :title }
              end
              assert_equal 4, results.size

              assert_equal 2, results.total_pages
              assert_equal 2, results.current_page
              assert_equal 1, results.previous_page
              assert_equal nil, results.next_page

              assert_equal 'Test6', results.first.title
            end

            should "not find a missing (third) page" do
              results = ActiveRecordArticle.search :page => 3, :per_page => 5 do |search|
                search.query { |query| query.string @q }
                search.sort  { by :title }
              end
              assert_equal 0, results.size

              assert_equal 2, results.total_pages
              assert_equal 3, results.current_page
              assert_equal 2, results.previous_page
              assert_equal nil, results.next_page

              assert_nil results.first
            end

            should "find second page with four loaded models" do
              results = ActiveRecordArticle.search :load => true, :page => 2, :per_page => 5 do |search|
                search.query { |query| query.string @q }
                search.sort  { by :title }
              end
              assert_equal 4, results.size
              assert results.all? { |r| assert_instance_of ActiveRecordArticle, r }
              assert_equal 'Test6', results.first.title
            end

          end

          context "with from/size" do

            should "find first page with five results" do
              results = ActiveRecordArticle.search do |search|
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

            should "find second page with five results" do
              results = ActiveRecordArticle.search do |search|
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

            should "not find a missing (third) page" do
              results = ActiveRecordArticle.search do |search|
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

      end

      context "with proxy" do

        should "allow access to Tire instance methods" do
          a = ActiveRecordClassWithTireMethods.create :title => 'One'
          assert_equal "THIS IS MY INDEX!", a.index
          assert_instance_of Tire::Index, a.tire.index
          assert a.tire.index.exists?, "Index should exist"
        end

        should "allow access to Tire class methods" do
          class ::ActiveRecordClassWithTireMethods < ActiveRecord::Base
            def self.search(*)
              "THIS IS MY SEARCH!"
            end
          end

          ActiveRecordClassWithTireMethods.create :title => 'One'
          ActiveRecordClassWithTireMethods.tire.index.refresh

          assert_equal "THIS IS MY SEARCH!", ActiveRecordClassWithTireMethods.search

          results = ActiveRecordClassWithTireMethods.tire.search 'one'

          assert_equal 'One', results.first.title
        end

      end

      context "with dynamic index name" do
        setup do
          @a = ActiveRecordClassWithDynamicIndexName.create! :title => 'Test'
          @a.index.refresh
        end

        should "search in proper index" do
          assert_equal 'dynamic_index', ActiveRecordClassWithDynamicIndexName.index.name
          assert_equal 'dynamic_index', @a.index.name

          results = ActiveRecordClassWithDynamicIndexName.search 'test'
          assert_equal 'dynamic_index', results.first._index
        end
      end

      context "within Rails" do

        setup do
          module ::Rails; end

          a = ActiveRecordArticle.new :title => 'Test'
          a.comments.build :author => 'fool', :body => 'Works!'
          a.stats.build    :pageviews  => 12, :period => '2011-08'
          a.save!
          @id = a.id.to_s

          a.index.refresh
          @item = ActiveRecordArticle.search('test').first
        end

        should "have access to indexed properties" do
          assert_equal 'Test', @item.title
          assert_equal 'fool', @item.comments.first.author
          assert_equal 12,     @item.stats.first.pageviews
        end

        should "load the underlying models" do
          assert_instance_of Results::Item, @item
          assert_instance_of ActiveRecordArticle, @item.load
          assert_equal      'Test', @item.load.title

          assert_instance_of Results::Item, @item.comments.first
          assert_instance_of ActiveRecordComment, @item.comments.first.load
          assert_equal      'fool', @item.comments.first.load.author
        end

        should "load the underlying model with options" do
          ActiveRecordArticle.expects(:find).with(@id, :include => 'comments')
          @item.load(:include => 'comments')
        end

      end

      context "with multiple class instances in one index" do
         setup do
           ActiveRecord::Schema.define do
             create_table(:active_record_assets)    { |t| t.string :title, :timestamp }
             create_table(:active_record_model_one) { |t| t.string :title, :timestamp }
             create_table(:active_record_model_two) { |t| t.string :title, :timestamp }
           end

           ActiveRecordModelOne.create :title => 'Title One', timestamp: Time.now.to_i
           ActiveRecordModelTwo.create :title => 'Title Two', timestamp: Time.now.to_i
           ActiveRecordModelOne.tire.index.refresh
           ActiveRecordModelTwo.tire.index.refresh


           ActiveRecordVideo.create! :title => 'Title One', timestamp: Time.now.to_i
           ActiveRecordPhoto.create! :title => 'Title Two', timestamp: Time.now.to_i
           ActiveRecordAsset.tire.index.refresh
         end

         teardown do
           ActiveRecordModelOne.destroy_all
           ActiveRecordModelTwo.destroy_all
           ActiveRecordModelOne.tire.index.delete
           ActiveRecordModelTwo.tire.index.delete

           ActiveRecordAsset.destroy_all
           ActiveRecordAsset.tire.index.delete
           ActiveRecordModelOne.destroy_all
         end

         should "eagerly load instances of multiple classes, from multiple indices" do
           s = Tire.search ['active_record_model_one', 'active_record_model_two'], :load => true do
             query { string 'title' }
             sort  { by :timestamp }
           end

           # puts s.results[0].inspect

           assert_equal 2, s.results.length
           assert_instance_of ActiveRecordModelOne, s.results[0]
           assert_instance_of ActiveRecordModelTwo, s.results[1]
         end

         should "eagerly load all STI descendant records" do
           s = Tire.search('active_record_assets', :load => true) do
             query { string 'title' }
             sort  { by :timestamp }
           end

           assert_equal 2, s.results.length
           assert_instance_of ActiveRecordVideo,  s.results[0]
           assert_instance_of ActiveRecordPhoto,  s.results[1]
         end
      end

      context "with namespaced models" do
        setup do
           ActiveRecord::Schema.define { create_table(:active_record_namespace_my_models) { |t| t.string :title, :timestamp } }

           ActiveRecordNamespace::MyModel.create :title => 'Test'
           ActiveRecordNamespace::MyModel.tire.index.refresh
        end

        teardown do
           ActiveRecordNamespace::MyModel.destroy_all
           ActiveRecordNamespace::MyModel.tire.index.delete
        end

        should "save document into index on save and find it" do
          results = ActiveRecordNamespace::MyModel.search 'test'

          assert       results.any?, "No results returned: #{results.inspect}"
          assert_equal 1, results.count

          assert_instance_of Results::Item, results.first
        end

        should "eagerly load the records from returned hits" do
          results = ActiveRecordNamespace::MyModel.search 'test', :load => true

          assert             results.any?, "No results returned: #{results.inspect}"
          assert_instance_of ActiveRecordNamespace::MyModel, results.first
          assert_equal       ActiveRecordNamespace::MyModel.find(1), results.first
        end

      end

      context "multi search" do
        setup do
          # Tire.configure { logger STDERR }
          ActiveRecordArticle.create! :title => 'Test'
          ActiveRecordArticle.create! :title => 'Pest'
          ActiveRecordArticle.index.refresh
        end

        should "return multiple result sets" do
          results = ActiveRecordArticle.multi_search do
            search do
              query { match :title, 'test' }
            end
            search search_type: 'count' do
              query { match :title, 'pest' }
            end
            search :articles, index: 'articles-test', type: 'article' do
              query { all }
            end
          end

          assert_equal 3, results.size

          assert_equal 1, results[0].size
          assert_equal 1, results[0].total

          assert_equal 0, results[1].size
          assert_equal 1, results[1].total

          assert_equal 5, results[:articles].size
        end

        should "return model instances with the :load option" do
          results = ActiveRecordArticle.multi_search do
            search :items do
              query { match :title, 'test' }
            end
            search :models, :load => true do
              query { match :title, 'test' }
            end
          end

          assert_instance_of Tire::Results::Item, results[:items].first
          assert_instance_of ActiveRecordArticle, results[:models].first
        end

      end

      context "percolated search" do
        setup do
          delete_registered_queries
          delete_percolator_index if ENV['TRAVIS']
          ActiveRecordModelWithPercolation.index.register_percolator_query('alert') { string 'warning' }
          Tire.index('_percolator').refresh
        end

        teardown do
          ActiveRecordModelWithPercolation.index.unregister_percolator_query('alert') { string 'warning' }
        end

        should "return matching queries when percolating" do
          a = ActiveRecordModelWithPercolation.new :title => 'Warning!'
          assert_contains a.percolate, 'alert'
        end

        should "return matching queries when saving" do
          a = ActiveRecordModelWithPercolation.create! :title => 'Warning!'
          assert_contains a.matches, 'alert'
        end
      end

    end

    private

    def delete_registered_queries
      Configuration.client.delete("#{Configuration.url}/_percolator/active_record_model_with_percolations/alert") rescue nil
    end

    def delete_percolator_index
      Configuration.client.delete("#{Configuration.url}/_percolator") rescue nil
    end

  end

end
