require 'test_helper'
require 'time'

module Tire

  class LoggerTest < Test::Unit::TestCase
    include Tire

    context "Logger" do

      context "initialized with an IO object" do

        should "take STDOUT" do
          assert_nothing_raised do
            logger = Logger.new STDOUT
          end
        end

        should "write to STDERR" do
          STDERR.expects(:write).with('BOOM!')
          logger = Logger.new STDERR
          logger.write('BOOM!')
        end

      end

      context "initialized with file" do
        teardown { File.delete('myfile.log') }

        should "create the file" do
          assert_nothing_raised do
            logger = Logger.new 'myfile.log'
            assert File.exists?('myfile.log')
          end
        end

        should "write to file" do
          File.any_instance.expects(:write).with('BOOM!')
          logger = Logger.new 'myfile.log'
          logger.write('BOOM!')
        end

      end

    end

    context "levels" do

      should "have the default level" do
        logger = Logger.new STDERR
        assert_equal 'info', logger.level
      end

      should "set the level" do
        logger = Logger.new STDERR, :level => 'debug'
        assert_equal 'debug', logger.level
      end

    end

    context "tracing requests" do
      setup do
        Time.stubs(:now).returns(Time.parse('2011-03-19 11:00'))
        @logger = Logger.new STDERR
      end

      should "log request in correct format" do
        log = (<<-"log;").gsub(/^ +/, '')
          # 2011-03-19 11:00:00:000 [_search] (["articles", "users"])
          #
          curl -X GET http://...

        log;
        @logger.expects(:write).with do |payload|
          payload =~ Regexp.new( Regexp.escape('2011-03-19 11:00:00') )
          payload =~ Regexp.new( Regexp.escape('_search') )
          payload =~ Regexp.new( Regexp.escape('(["articles", "users"])') )
        end
        @logger.log_request('_search', ["articles", "users"], 'curl -X GET http://...')
      end

      should "log response in correct format" do
        json = (<<-"json;").gsub(/^\s*/, '')
        {
          "took" : 4,
          "hits" : {
            "total" : 20,
            "max_score" : 1.0,
            "hits" : [ {
              "_index" : "articles",
              "_type" : "article",
              "_id" : "Hmg0B0VSRKm2VAlsasdnqg",
              "_score" : 1.0, "_source" : { "title" : "Article 1",  "published_on" : "2011-01-01" }
            }, {
              "_index" : "articles",
              "_type" : "article",
              "_id" : "booSWC8eRly2I06GTUilNA",
              "_score" : 1.0, "_source" : { "title" : "Article 2", "published_on" : "2011-01-12" }
            }
            ]
          }
        }
        json;
        log  = (<<-"log;").gsub(/^\s*/, '')
          # 2011-03-19 11:00:00:000 [200 OK] (4 msec)
          #
        log;
        # log += json.split.map { |line| "# #{line}" }.join("\n")
        json.each_line { |line| log += "# #{line}" }
        log += "\n\n"
        @logger.expects(:write).with do |payload|
          payload =~ Regexp.new( Regexp.escape('2011-03-19 11:00:00') )
          payload =~ Regexp.new( Regexp.escape('[200 OK]') )
          payload =~ Regexp.new( Regexp.escape('(4 msec)') )
          payload =~ Regexp.new( Regexp.escape('took') )
          payload =~ Regexp.new( Regexp.escape('hits') )
          payload =~ Regexp.new( Regexp.escape('_score') )
        end
        @logger.log_response('200 OK', 4, json)
      end

    end

  end
end
