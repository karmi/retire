require 'bundler'
Bundler::GemHelper.install_tasks

task :default => :test

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
end

namespace :test do
  Rake::TestTask.new(:unit) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = 'test/unit/*_test.rb'
    test.verbose = true
  end
  Rake::TestTask.new(:integration) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = 'test/integration/*_test.rb'
    test.verbose = true
  end
end

# Generate documentation
begin
  require 'sdoc'
rescue LoadError
end
require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Slingshot"
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

# Generate coverage reports
begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.rcov_opts = ['--exclude', 'gems/*']
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install rcov"
  end
end

namespace :web do

  desc "Generate and update website documentation"
  task :update do
    system "rocco examples/slingshot-dsl.rb"
    html = File.read('examples/slingshot-dsl.html').gsub!(/slingshot\-dsl\.rb/, 'slingshot.rb')
    File.open('examples/slingshot-dsl.html', 'w') { |f| f.write html }
    system "open examples/slingshot-dsl.html"

    # Update the Github website
    current_branch = `git branch --no-color`.split("\n").select { |line| line =~ /^\* / }.to_s.gsub(/\* (.*)/, '\1')
    (puts "Unable to determine current branch"; exit(1) ) unless current_branch
    system "git stash save && git checkout web"
    system "cp examples/slingshot-dsl.html index.html"
    system "git add index.html && git co -m 'Updated Slingshot website'"
    system "git push origin web:gh-pages -f"
    system "git checkout #{current_branch} && git stash pop"
  end
end
