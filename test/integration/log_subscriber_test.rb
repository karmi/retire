require 'test_helper'
require "active_support/log_subscriber/test_helper"
require 'tire/rails/log_subscriber'
require 'tire/rails/instrumentation'

module Tire
  module Rails

    class LogSubscriberTest < Test::Unit::TestCase
      include Test::Integration
      include ActiveSupport::LogSubscriber::TestHelper

      def setup
        super

        # Make sure instrumentation wraps the perform method
        Tire::Search::Search.module_eval do
          include Tire::Rails::Instrumentation
        end
        
        # Attach log subscriber
        Tire::Rails::LogSubscriber.attach_to :tire
        
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
        end

        ActiveRecordArticle.destroy_all
        Tire.index('active_record_articles').delete

        1.upto(9) { |number| ActiveRecordArticle.create :title => "Test#{number}" }
        ActiveRecordArticle.index.refresh

        load File.expand_path('../../models/active_record_models.rb', __FILE__)
      end

      def teardown
        ActiveRecordArticle.destroy_all
        Tire.index('active_record_articles').delete
        super
      end

      context "Rails notifications" do

        should "log event on search" do
          ActiveRecordArticle.search '*', :load => true
          wait
          assert_equal 1, @logger.logged(:debug).size
          assert_match /Tire/, @logger.logged(:debug).last
        end
      
      end

    end

  end
end

