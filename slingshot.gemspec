# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "slingshot/version"

Gem::Specification.new do |s|
  s.name        = "slingshot"
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

  s.extra_rdoc_files  = [ "README.rdoc", "MIT-LICENSE" ]
  s.rdoc_options      = [ "--charset=UTF-8" ]

  s.required_rubygems_version = ">= 1.3.6"

  s.add_development_dependency "turn"
  s.add_development_dependency "shoulda"

  s.description = <<-DESC
   Ruby API for the ElasticSearch search engine/database.
   A work in progress, currently.
  DESC
end
