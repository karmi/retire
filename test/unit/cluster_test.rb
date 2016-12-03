require 'test_helper'

module Tire

  class ClusterTest < Test::Unit::TestCase

    context "Cluster" do

      should "perform block on initialize" do
        Cluster.any_instance.expects(:foo)

        Cluster.new { foo }
      end

      context "#url" do

        should "append _cluster to url" do
          assert Cluster.new.url.match /_cluster$/
        end

      end

      context "#health" do

        should "request health status" do
          Configuration.client.expects(:get).with do |url, payload|
            assert url.match /_cluster\/health/
          end.returns mock_response({}.to_json)

          Cluster.new.health
        end

        should "pass options as url parameters" do
          Configuration.client.expects(:get).with do |url, payload|
            assert url.match /\?timeout=3s/
          end.returns mock_response({}.to_json)

          Cluster.new.health timeout: "3s"
        end

        should "return response" do
          health_response = {
            "cluster_name"          => "cluster_1",
            "status"                => "yellow",
            "timed_out"             => false,
            "number_of_nodes"       => 1,
            "number_of_data_nodes"  => 1,
            "active_primary_shards" => 36,
            "active_shards"         => 36,
            "relocating_shards"     => 0,
            "initializing_shards"   => 0,
            "unassigned_shards"     => 35
          }

          Configuration.client.expects(:get).returns mock_response(health_response.to_json)

          assert Cluster.new.health == health_response
        end

      end

    end

  end

end