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

namespace :web do

  desc "Update the Github website"
  task :update => :generate do
    current_branch = `git branch --no-color`.
                       split("\n").
                       select { |line| line =~ /^\* / }.
                       first.to_s.
                       gsub(/\* (.*)/, '\1')
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
