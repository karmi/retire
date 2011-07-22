require 'test_helper'

module Tire

  class AttachmentsIntegrationTest < Test::Unit::TestCase
    include Test::Integration

    context "Attachments support" do

      setup do
        # Tire.configure { logger STDERR, :level => 'debug' }
        @index = Tire.index 'attachments-tire-test' do
          delete
          create :mappings => {
            :document => {
              :properties => {
                :attachment => {
                  :type => 'attachment',
                  :fields => {
                    :_name         => { :store => 'yes' },
                    :_content_type => { :store => 'yes' },
                    :content       => { :store => 'yes' },
                    :author        => { :store => 'yes' },
                    :title         => { :store => 'yes' },
                    :date          => { :store => 'yes' }
                  }
                }
              }
            }
          }
        end
      end

      teardown do
        # @index.delete
      end

      should "store document with attachment" do
        @index.store :id => 1, :attachment => File.new( fixtures_path.join('test.rtf').to_s )
        document = @index.retrieve :document, 1

        assert_instance_of Attachment,  document.attachment
        assert_equal 'test.rtf',        document.attachment.filename
        assert_equal 'application/rtf', document.attachment.content_type

        assert_match %r|\{\\rtf1\\ansi\\ansicpg1250|, document.attachment.content
      end

      should "find the document by metadata" do
        @index.store :id => 1, :attachment => File.new( fixtures_path.join('test.doc').to_s )
        @index.refresh

        results = Tire.search @index.name do
          query { string 'john' }
        end.results

        assert_equal 1, results.size
        assert_equal 'test.doc',   results.first.attachment.filename
      end

      should "find the document by metadata with fields highlighted" do
        @index.store :id => 1, :attachment => File.new( fixtures_path.join('test.doc').to_s )
        @index.refresh

        results = Tire.search @index.name do
          query     { string 'john' }
          highlight :author
        end.results

        assert_match %r|<em>John</em> Smith|, results.first.highlight.author.to_s
      end

    end
  end

end
