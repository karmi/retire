# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "slingshot/version"

Gem::Specification.new do |s|
  s.name        = "slingshot-rb"
  s.version     = Slingshot::VERSION
  s.platform    = Gem::Platform::RUBY
  s.summary       = "Ruby API for ElasticSearch"
  s.homepage      = "http://github.com/karmi/slingshot"
  s.authors       = [ 'Karel Minarik' ]
  s.email         = 'karmi@karmi.cz'

  s.rubyforge_project = "slingshot"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.require_paths = ["lib"]

  s.extra_rdoc_files  = [ "README.markdown", "MIT-LICENSE" ]
  s.rdoc_options      = [ "--charset=UTF-8" ]

  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency "bundler",     "~> 1.0.0"
  s.add_dependency "rest-client", "~> 1.6.0"
  s.add_dependency "yajl-ruby",   "> 0.7.9"

  s.add_development_dependency "turn"
  s.add_development_dependency "shoulda"
  s.add_development_dependency "mocha"
  s.add_development_dependency "sdoc"
  s.add_development_dependency "rcov"
  s.add_development_dependency "activemodel"
  s.add_development_dependency "activerecord"

  s.description = <<-DESC
   Ruby API for the ElasticSearch search engine/database.
   A work in progress, currently.
  DESC
end
