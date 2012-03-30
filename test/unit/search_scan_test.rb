require 'test_helper'

module Tire
  module Search
    class ScanTest < Test::Unit::TestCase

      context "Scan" do
        setup { Configuration.reset }

        should "initialize the search object" do
          Search.expects(:new).with { |index| index == ['index1', 'index2'] }
          Scan.new(['index1', 'index2'])
          # Scan.new('webexpo')
        end

        should "fetch the initial scroll ID" do
          s = Scan.new('webexpo')
          # p s.scroll_id
          s.each do |d|
            p d
            p '-'*100
          end
        end

      end

    end
  end
end
