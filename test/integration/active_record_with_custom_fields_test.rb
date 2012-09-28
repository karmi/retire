require_relative '../test_helper'
require_relative '../models/active_record_models'

module Tire

  class ActiveRecordWithCustomFieldsTest < Test::Unit::TestCase
    include Test::Integration

    def setup
      super
      ActiveRecord::Base.establish_connection( :adapter => 'sqlite3', :database => ":memory:" )

      ActiveRecord::Schema.define(:version => 1) do

        create_table :active_record_news_stories do |t|
          t.string  :title, :null => false
          t.text    :content, :null => false
          t.integer :category_id, :null => false
          t.integer :author_id, :null => false
        end

        create_table :active_record_categories do |t|
          t.string :name, :null => false
        end

        create_table :active_record_authors do |t|
          t.string :name, :null => false
        end

      end
    end

    context "Testing :as properties" do

      def clean
        [ ActiveRecordNewsStory, ActiveRecordCategory, ActiveRecordAuthor ].each(&:destroy_all)
        Tire.index('active_record_news_stories').delete
      end

      setup do
        clean

        @category = ActiveRecordCategory.create!(:name => 'Science Fiction')
        @author   = ActiveRecordAuthor.create!(:name => 'Phillip K. Dick')
      end

      teardown do
        clean
      end

      should 'correcty add the :as fields defined in the model' do
        news_story = ActiveRecordNewsStory.new(
          :title => 'New book',
          :content => 'A new book has been published on sci-fi',
          :author_id => @author.id,
          :category_id => @category.id)

        data_hash = news_story.to_indexed_hash

        assert_equal @category.name, data_hash[:category_name]
        assert_equal @author.name, data_hash[:author_name]
        assert_equal @category.name, data_hash[:block_category_name]
        assert_equal @author.name, data_hash[:string_author_name]
        assert_equal @category.name, data_hash[:lambda_category_name]
      end

    end

  end

end
