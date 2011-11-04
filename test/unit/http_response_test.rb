require 'test_helper'

module Tire
  module HTTP

    class ResponseTest < Test::Unit::TestCase

      context "Response" do

        should "take response body, code and headers on initialization" do
          response = Response.new "http response body",
                                  200,
                                  :content_length => 20,
                                  :content_encoding => 'gzip'

          assert_equal "http response body", response.body
          assert_equal 200, response.code
        end

        should "not require headers" do
          assert_nothing_raised do
            Response.new "Forbidden", 403
          end
        end

        should "return success" do
          responses = []
          responses << Response.new('OK', 200)
          responses << Response.new('Redirect', 302)

          responses.each { |response| assert response.success? }

          assert ! Response.new('NotFound', 404).success?
        end

        should "return failure" do
          assert Response.new('NotFound', 404).failure?
        end

        should "return string representation" do
          assert_equal "200 : Hello", Response.new('Hello', 200).to_s
        end

      end

    end

  end
end
