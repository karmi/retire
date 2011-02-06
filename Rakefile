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
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Slingshot"
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
