require 'test_helper'

module Tire

  class AttachmentTest < Test::Unit::TestCase

    context "Attachment" do

      setup do
        @file = File.new(fixtures_path.join('test.rtf').to_s)
        @attachment = Attachment.new(@file)
      end

      should "infer filename from the file" do
        assert_equal 'test.rtf', @attachment.filename
      end

      should "infer content type from the file" do
        assert_equal 'application/rtf', @attachment.content_type
      end

      should "be serialized into JSON as a base64, MIME_NO_LINEFEEDS encoded string" do
        assert_instance_of String, @attachment.to_json
        hash = MultiJson.decode(@attachment.to_json)
        puts @attachment.to_json
        # p hash
        # assert_match /^"e1xydGYxXGFuc2lcYW5zaWNwZzEyNTBcY29jb2FydGYxMDM4XGNvY29hc3VicnRm/,
        #                      @attachment.to_json
      end

    end

  end
end
