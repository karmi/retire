source "http://rubygems.org"

# Specify your gem's dependencies in tire.gemspec
gemspec

platform :ruby do
  gem "yajl-ruby",   "~> 1.0"
  gem "sqlite3"
  gem "bson_ext"
  gem "curb"
  gem "oj"
end

unless defined?(RUBY_VERSION) && RUBY_VERSION < '1.9'
  gem "turn", "~> 0.9"
end

platform :jruby do
  gem "jdbc-sqlite3"
  gem "activerecord-jdbcsqlite3-adapter"
end