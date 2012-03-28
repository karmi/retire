require 'rubygems'
require 'bundler/setup'

require 'pathname'
require 'test/unit'

require 'yajl/json_gem'
require 'sqlite3'

require 'shoulda'
require 'turn/autorun' unless ENV["TM_FILEPATH"] || ENV["CI"] || defined?(RUBY_VERSION) && RUBY_VERSION < '1.9'
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
    ::RestClient.delete "#{URL}/articles-test"  rescue nil
  end
end
