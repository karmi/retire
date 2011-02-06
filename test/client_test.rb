require 'test_helper'

module Slingshot

  class ClientTest < Test::Unit::TestCase

    context "Base" do
      setup { @http ||= Client::Base.new }

      should "have abstract methods" do
        assert_raise(ArgumentError) { @http.post               }
        assert_raise(ArgumentError) { @http.post 'URL'         }
        assert_raise(NoMethodError) { @http.post 'URL', 'DATA' }

        assert_raise(ArgumentError) { @http.delete       }
        assert_raise(NoMethodError) { @http.delete 'URL' }
      end
    end

    context "RestClient" do

      should "be default" do
        assert_equal Client::RestClient, Configuration.client
      end

      
    end

  end

end
