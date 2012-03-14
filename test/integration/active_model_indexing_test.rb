require 'test_helper'
require 'active_record'
require 'delayed_job'
require 'pry'

module Tire

  class ActiveModelSearchableIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    class ::ActiveModelArticleWithCustomAsSerialization < ActiveModelArticleWithCallbacks
      mapping do
        indexes :title
        indexes :content
        indexes :characters,  :as => 'content.length'
        indexes :readability, :as => proc {
                                       content.split(/\W/).reject { |t| t.blank? }.size /
                                       content.split(/\./).size
                                     }
      end
    end

    class ::AssociatedModel < ActiveRecord::Base
      include Tire::Model::Search
      include Tire::Model::Callbacks

      has_many :articles,    :class_name => "ActiveModelArticleWithAssociation",    :foreign_key => "article_id"

      mapping do
        indexes :first_name
        indexes :last_name
      end
    end

    class ::ActiveModelArticleWithAssociation < ActiveRecord::Base
      include Tire::Model::Search
      include Tire::Model::Callbacks

      mapping do
        indexes :title
        indexes :content
        indexes :associated_model, :class => AssociatedModel do
          indexes :first_name
        end
      end
    end

    def setup
      super
      ActiveModelArticleWithCustomAsSerialization.index.delete
      ActiveModelArticleWithAssociation.index.delete
      AssociatedModel.index.delete
    end

    def teardown
      super
      ActiveModelArticleWithCustomAsSerialization.index.delete
      ActiveModelArticleWithAssociation.index.delete
      AssociatedModel.index.delete
    end

    context "ActiveModel serialization" do

      setup do
        @model = ActiveModelArticleWithCustomAsSerialization.new \
                   :id      => 1, 
                   :title   => 'Test article',
                   :content => 'Lorem Ipsum. Dolor Sit Amet.'
        @model.update_index
        @model.index.refresh
      end

      should "serialize the content length" do
        m = ActiveModelArticleWithCustomAsSerialization.search('*').first
        assert_equal 28, m.characters
        assert_equal 2,  m.readability
      end

    end

    context "ActiveModel serialization with association" do

      setup do
        ActiveRecord::Base.establish_connection( :adapter => 'sqlite3', :database => ":memory:" )

        ActiveRecord::Migration.verbose = false
        ActiveRecord::Schema.define(:version => 1) do
          create_table :associated_models do |t|
            t.string   :first_name
            t.string   :last_name
          end
          create_table :active_model_article_with_associations do |t|
            t.string     :title
            t.text       :content
            t.integer    :associated_model_id
          end
          create_table :delayed_jobs do |t|
            t.integer  "priority",   :default => 0
            t.integer  "attempts",   :default => 0
            t.text     "handler"
            t.text     "last_error"
            t.datetime "run_at"
            t.datetime "locked_at"
            t.datetime "failed_at"
            t.string   "locked_by"
            t.datetime "created_at"
            t.datetime "updated_at"
            t.string   "queue"
          end
        end

        Delayed::Worker.backend = :active_record

        @associated_model = AssociatedModel.create :first_name => 'Jack', :last_name => 'Doe'
        @model = ActiveModelArticleWithAssociation.create \
          :title => 'Sample Title',
          :content => 'Test article',
          :associated_model_id => @associated_model.id
      end

      teardown do
        Delayed::Job.all.each do |job|
          job.destroy
        end

        ActiveModelArticleWithAssociation.destroy_all
        AssociatedModel.destroy_all

        AssociatedModel.after_update.clear
      end

      context 'to_indexed_json' do
        should 'include the associated model as a nested attribute' do
          indexed_json = "{\"content\":\"Test article\",\"title\":\"Sample Title\",\"associated_model\":{\"first_name\":\"Jack\"}}"
          assert_equal @model.to_indexed_json, indexed_json
        end
      end

      context 'without delayed job' do
        setup do
          Tire.configure {
            nested_attributes do
              nest :associated_model => :active_model_article_with_association
            end
          }
        end

        should "update the index if associated model is updated" do
          puts AssociatedModel._update_callbacks.count
          @associated_model.first_name = 'Jim'
          @associated_model.save
          sleep(2)
          m = ActiveModelArticleWithAssociation.search('*').first
          assert_equal @associated_model.first_name, m.associated_model.first_name
        end
      end

      context 'with delayed job' do
        setup do
          Tire.configure {
            nested_attributes :delayed_job => true do
              nest :associated_model => :active_model_article_with_association
            end
          }
        end

        should "update the index if associated model is updated" do
          assert_equal 0, Delayed::Job.count
          @associated_model.first_name = 'Jim'
          @associated_model.save
          assert_equal 1, Delayed::Job.count
          Delayed::Job.all.each do |job|
            job.payload_object.perform
            job.destroy
          end
          sleep(2)
          assert_equal 0, Delayed::Job.count
          m = ActiveModelArticleWithAssociation.search('*').first
          assert_equal @associated_model.first_name, m.associated_model.first_name
        end

        should "not update the index if associated model is updated if no delayed jobs server is running" do
          puts AssociatedModel._update_callbacks.count
          @associated_model.first_name = 'Jim'
          @associated_model.save
          sleep(2)
          m = ActiveModelArticleWithAssociation.search('*').first
          assert_equal 'Jack', m.associated_model.first_name
        end

        should "not reindex if none of the indexed attributes gets updated" do
          @associated_model.last_name = 'Robinson'
          @associated_model.save
          assert_equal 0, Delayed::Job.count
        end
      end
    end

  end

  def get_reindex_jobs
    Delayed::Job.all.map do |job|
      job.payload_object if job.payload_object.class == Tire::Job::ReindexJob
    end.compact
  end
end
