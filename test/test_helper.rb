require 'rubygems'

require 'pathname'
require 'test/unit'

require 'yajl/json_gem'
require 'sqlite3'

require 'shoulda'
require 'turn' unless ENV["TM_FILEPATH"]
require 'mocha'

require 'tire'

Dir[File.dirname(__FILE__) + '/models/**/*.rb'].each { |m| require m }

class Test::Unit::TestCase

  def mock_response(body, code=200)
    stub(:body => body, :code => code)
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
  end

  def teardown
    ::RestClient.delete "#{URL}/articles-test"  rescue nil
  end
end
