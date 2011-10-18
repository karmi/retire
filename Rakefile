require 'bundler'
Bundler::GemHelper.install_tasks

task :default => :test

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.test_files = FileList['test/unit/*_test.rb', 'test/integration/*_test.rb']
  test.verbose = true
  # test.warning = true
end

namespace :test do
  Rake::TestTask.new(:unit) do |test|
    test.libs << 'lib' << 'test'
    test.test_files = FileList["test/unit/*_test.rb"]
    test.verbose = true
  end
  Rake::TestTask.new(:integration) do |test|
    test.libs << 'lib' << 'test'
    test.test_files = FileList["test/integration/*_test.rb"]
    test.verbose = true
  end
end

# Generate documentation
begin
  require 'rdoc'
  begin; require 'sdoc'; rescue LoadError; end
  require 'rdoc/task'
  Rake::RDocTask.new do |rdoc|
    rdoc.rdoc_dir = 'rdoc'
    rdoc.title = "Tire"
    rdoc.rdoc_files.include('README.markdown')
    rdoc.rdoc_files.include('lib/**/*.rb')
  end
rescue LoadError
  task :rdoc do
    abort "[!] RDoc gem is not available."
  end
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
    abort "[!] RCov gem is not available."
  end
end

namespace :web do

  desc "Update the Github website"
  task :update => :generate do
    current_branch = `git branch --no-color`.split("\n").select { |line| line =~ /^\* / }.to_s.gsub(/\* (.*)/, '\1')
    (puts "Unable to determine current branch"; exit(1) ) unless current_branch
    system "git checkout web"
    system "cp examples/tire-dsl.html index.html"
    system "git add index.html && git co -m 'Updated Tire website'"
    system "git push origin web:gh-pages -f"
    system "git checkout #{current_branch}"
  end

  desc "Generate the Rocco documentation page"
  task :generate do
    system "rocco examples/tire-dsl.rb"
    html = File.read('examples/tire-dsl.html').gsub!(/>tire\-dsl\.rb</, '>tire.rb<')
    File.open('examples/tire-dsl.html', 'w') { |f| f.write html }
    system "open examples/tire-dsl.html"
  end
end
