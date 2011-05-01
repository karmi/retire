require 'test_helper'

module Tire

  class ClientTest < Test::Unit::TestCase

    context "Base" do
      setup { @http ||= Client::Base.new }

      should "have abstract methods" do
        assert_raise(ArgumentError) { @http.get                }
        assert_raise(NoMethodError) { @http.get 'URL'          }

        assert_raise(ArgumentError) { @http.post               }
        assert_raise(ArgumentError) { @http.post 'URL'         }
        assert_raise(NoMethodError) { @http.post 'URL', 'DATA' }

        assert_raise(ArgumentError) { @http.put               }
        assert_raise(ArgumentError) { @http.put 'URL'         }

        assert_raise(ArgumentError) { @http.delete       }
        assert_raise(NoMethodError) { @http.delete 'URL' }
      end
    end

    context "RestClient" do

      should "be default" do
        assert_equal Client::RestClient, Configuration.client
      end

      should "respond to HTTP methods" do
        assert_respond_to Client::RestClient, :get
        assert_respond_to Client::RestClient, :post
        assert_respond_to Client::RestClient, :put
        assert_respond_to Client::RestClient, :delete
      end
      
    end

  end

end
