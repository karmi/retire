# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "tire/version"

Gem::Specification.new do |s|
  s.name        = "tire"
  s.version     = Tire::VERSION
  s.platform    = Gem::Platform::RUBY
  s.summary       = "Ruby client for ElasticSearch"
  s.homepage      = "http://github.com/karmi/tire"
  s.authors       = [ 'Karel Minarik' ]
  s.email         = 'karmi@karmi.cz'

  s.rubyforge_project = "tire"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  s.require_paths = ["lib"]

  s.extra_rdoc_files  = [ "README.markdown", "MIT-LICENSE" ]
  s.rdoc_options      = [ "--charset=UTF-8" ]

  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency "rake",        "~> 0.8.0"
  s.add_dependency "bundler",     "~> 1.0.0"
  s.add_dependency "rest-client", "~> 1.6.0"
  s.add_dependency "yajl-ruby",   "~> 0.8.0"
  s.add_dependency "activemodel", "~> 3.0.7"

  s.add_development_dependency "turn"
  s.add_development_dependency "shoulda"
  s.add_development_dependency "mocha"
  s.add_development_dependency "sdoc"
  s.add_development_dependency "rcov"
  s.add_development_dependency "activerecord"
  s.add_development_dependency "supermodel"

  s.description = <<-DESC
   Tire is a Ruby client for the ElasticSearch search engine/database.

   It provides Ruby-like API for fluent communication with the ElasticSearch server
   and blends with ActiveModel class for convenient usage in Rails applications.

   It allows to delete and create indices, define mapping for them, supports
   the bulk API, and presents an easy-to-use DSL for constructing your queries.

   It has full ActiveRecord/ActiveModel compatibility, allowing you to index
   your models (incrementally upon saving, or in bulk), searching and
   paginating the results.
  DESC
end
