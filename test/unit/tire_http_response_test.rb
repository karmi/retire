require 'test_helper'

module Tire
  module HTTP
    class ResponseTest < Test::Unit::TestCase
      context "construction" do
        should "take response body, code and headers" do
          response = Response.new "http response body",
                                  200,
                                  :content_length => 20,
                                  :content_encoding => 'gzip'

          assert_equal "http response body", response.body
          assert_equal 200, response.code
        end
      end
    end
  end
end
