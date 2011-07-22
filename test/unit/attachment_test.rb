require 'test_helper'

module Tire

  class AttachmentTest < Test::Unit::TestCase

    context "Attachment" do

      context "initialized with a File" do

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

        should "read the content from file" do
          assert_equal fixture_file('test.rtf'), @attachment.content
        end

        should "base64 encode the content" do
          assert_match /e1xydGYxXGFuc2lcYW5zaWNwZzEyNTBcY29jb2FydGYxMDM4XGNvY29hc3VicnRmMzUw.*/,
                       @attachment.encode
        end

        should "base64 encode the content when converting to Hash" do
          assert_match /e1xydGYxXGFuc2lcYW5zaWNwZzEyNTBcY29jb2FydGYxMDM4XGNvY29hc3VicnRmMzUw.*/,
                       @attachment.to_hash[:content]
        end

        should "be properly serialized into JSON for ElasticSearch" do
          assert_instance_of String, @attachment.to_json
          hash = MultiJson.decode(@attachment.to_json)

          assert_equal 'test.rtf', hash['_name']
          assert_equal 'application/rtf', hash['_content_type']
          assert_match /e1xydGYxXGFuc2lcYW5zaWNwZzEyNTBcY29jb2FydGYxMDM4XGNvY29hc3VicnRmMzUw.*/,
                       hash['content']
        end

      end

      context "initialized with a Hash" do
        setup do
          @attachment = Attachment.new :_name => 'test.rtf',
                                       :_content_type => 'application/rtf',
                                       :content => encoded
        end

        should "properly set filename and content_type" do
          assert_equal 'test.rtf',        @attachment.filename
          assert_equal 'application/rtf', @attachment.content_type
        end

        should "decode the base64 encoded content" do
          assert_equal fixture_file('test.rtf'), @attachment.content
        end

      end

    end

    def encoded
      "e1xydGYxXGFuc2lcYW5zaWNwZzEyNTBcY29jb2FydGYxMDM4XGNvY29hc3VicnRmMzUwCntcZm9udHRibFxmMFxmc3dpc3NcZmNoYXJzZXQwIEhlbHZldGljYTt9CntcY29sb3J0Ymw7XHJlZDI1NVxncmVlbjI1NVxibHVlMjU1O30Ke1xpbmZvCntcdGl0bGUgVGVzdCBSVEYgZG9jdW1lbnR9CntcYXV0aG9yIEpvaG4gU21pdGh9CntcKlxjb21wYW55IE15IE9yZ2FuaXphdGlvbn19XHBhcGVydzExOTAwXHBhcGVyaDE2ODQwXG1hcmdsMTQ0MFxtYXJncjE0NDBcdmlld3c5MDAwXHZpZXdoODQwMFx2aWV3a2luZDAKXHBhcmRcdHg1NjZcdHgxMTMzXHR4MTcwMFx0eDIyNjdcdHgyODM0XHR4MzQwMVx0eDM5NjhcdHg0NTM1XHR4NTEwMlx0eDU2NjlcdHg2MjM2XHR4NjgwM1xxbFxxbmF0dXJhbFxwYXJkaXJuYXR1cmFsCgpcZjBcZnMyNCBcY2YwIFRlc3QgUlRGIGRvY3VtZW50LlwKXApMb3JlbSBpcHN1bSBkb2xvci59"
    end

  end
end
