require 'rubygems'
require 'bundler/setup'

require 'pathname'
require 'test/unit'

require 'yajl/json_gem'
require 'sqlite3'

require 'shoulda'
require 'turn/autorun' unless ENV["TM_FILEPATH"] || defined?(RUBY_VERSION) && RUBY_VERSION < '1.9'
require 'mocha'

require 'active_support/core_ext/hash/indifferent_access'

require 'tire'

# Require basic model files
#
require File.dirname(__FILE__) + '/models/active_model_article'
require File.dirname(__FILE__) + '/models/active_model_article_with_callbacks'
require File.dirname(__FILE__) + '/models/active_model_article_with_custom_document_type'
require File.dirname(__FILE__) + '/models/active_model_article_with_custom_index_name'
require File.dirname(__FILE__) + '/models/active_record_models'
require File.dirname(__FILE__) + '/models/article'
require File.dirname(__FILE__) + '/models/persistent_article'
require File.dirname(__FILE__) + '/models/persistent_article_in_namespace'
require File.dirname(__FILE__) + '/models/persistent_article_with_casting'
require File.dirname(__FILE__) + '/models/persistent_article_with_defaults'
require File.dirname(__FILE__) + '/models/persistent_articles_with_custom_index_name'
require File.dirname(__FILE__) + '/models/validated_model'

class Test::Unit::TestCase

  def assert_block(message=nil)
    raise Test::Unit::AssertionFailedError.new(message.to_s) if (! yield)
    return true
  end if defined?(RUBY_VERSION) && RUBY_VERSION < '1.9'

  def mock_response(body, code=200, headers={})
    Tire::HTTP::Response.new(body, code, headers)
  end

  def fixtures_path
    Pathname( File.expand_path( 'fixtures', File.dirname(__FILE__) ) )
  end

  def fixture_file(path)
    File.read File.expand_path( path, fixtures_path )
  end

end

module Test::Integration
  URL = "http://localhost:9200"

  def setup
    begin; Object.send(:remove_const, :Rails); rescue; end

    begin
      ::RestClient.get URL
    rescue Errno::ECONNREFUSED
      abort "\n\n#{'-'*87}\n[ABORTED] You have to run ElasticSearch on #{URL} for integration tests\n#{'-'*87}\n\n"
    end

    ::RestClient.delete "#{URL}/articles-test"     rescue nil
    ::RestClient.post   "#{URL}/articles-test", ''
    fixtures_path.join('articles').entries.each do |f|
      filename = f.to_s
      next if filename =~ /^\./
      ::RestClient.put "#{URL}/articles-test/article/#{File.basename(filename, '.*')}",
                       fixtures_path.join('articles').join(f).read
    end
    ::RestClient.post "#{URL}/articles-test/_refresh", ''

    Dir[File.dirname(__FILE__) + '/models/**/*.rb'].each { |m| load m }
  end

  def teardown
    %w[
      articles-test
      active_record_articles
      active_model_article_with_custom_as_serializations
      active_record_class_with_tire_methods
      mongoid_articles
      mongoid_class_with_tire_methods
      supermodel_articles
      dynamic_index
      model_with_nested_documents
      model_with_incorrect_mappings ].each do |index|
        ::RestClient.delete "#{URL}/#{index}" rescue nil
    end
  end
end
