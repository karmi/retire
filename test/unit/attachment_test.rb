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

        should "be serialized into JSON as a base64, MIME_NO_LINEFEEDS encoded string" do
          assert_instance_of String, @attachment.to_json
          puts @attachment.to_json
          hash = MultiJson.decode(@attachment.to_json)
          assert_match /"e1xydGYxXGFuc2lcYW5zaWNwZzEyNTBcY29jb2FydGYxMDM4XGNvY29hc3VicnRmMzUw.*/,
                       @attachment.to_json
        end

      end

      context "initialized with a Hash" do
        setup do
          @attachment = Attachment.new :_name => 'test.rtf',
                                       :_content_type => 'application/rtf',
                                       :content => DATA.read
        end

        should "" do
          
        end

      end

    end

  end
end

__END__
e1xydGYxXGFuc2lcYW5zaWNwZzEyNTBcY29jb2FydGYxMDM4XGNvY29hc3VicnRmMzUwCntcZm9udHRibFxmMFxmc3dpc3NcZmNoYXJzZXQwIEhlbHZldGljYTt9CntcY29sb3J0Ymw7XHJlZDI1NVxncmVlbjI1NVxibHVlMjU1O30Ke1xpbmZvCntcdGl0bGUgVGVzdCBSVEYgZG9jdW1lbnR9CntcYXV0aG9yIEpvaG4gU21pdGh9CntcKlxjb21wYW55IE15IE9yZ2FuaXphdGlvbn19XHBhcGVydzExOTAwXHBhcGVyaDE2ODQwXG1hcmdsMTQ0MFxtYXJncjE0NDBcdmlld3c5MDAwXHZpZXdoODQwMFx2aWV3a2luZDAKXHBhcmRcdHg1NjZcdHgxMTMzXHR4MTcwMFx0eDIyNjdcdHgyODM0XHR4MzQwMVx0eDM5NjhcdHg0NTM1XHR4NTEwMlx0eDU2NjlcdHg2MjM2XHR4NjgwM1xxbFxxbmF0dXJhbFxwYXJkaXJuYXR1cmFsCgpcZjBcZnMyNCBcY2YwIFRlc3QgUlRGIGRvY3VtZW50LlwKXApMb3JlbSBpcHN1bSBkb2xvci59