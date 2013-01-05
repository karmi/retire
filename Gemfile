source "http://rubygems.org"

# Specify your gem's dependencies in tire.gemspec
gemspec

platform :jruby do
  gem "jdbc-sqlite3"
  gem "activerecord-jdbcsqlite3-adapter"
  gem "json" if defined?(RUBY_VERSION) && RUBY_VERSION < '1.9'
end
