$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'rubygems'
require 'active_record'
require 'yajl/json_gem'
require 'tire'

### Remove existing indexes

%w(tire-test-blog-1 tire-test-blog-2).each do |index_name|
  Tire.index(index_name) { delete if exists? }
end

### Setup AR models

ActiveRecord::Base.establish_connection( :adapter => 'sqlite3', :database => ":memory:" )

ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define(:version => 1) do
  create_table :blogs do |t|
    t.string   :title
  end
  create_table :posts do |t|
    t.references :blog
    t.integer    :year
    t.string     :title
    t.text       :body
    t.timestamps
  end
end

class Blog < ActiveRecord::Base
  has_many :posts
end

class Post < ActiveRecord::Base
  include Tire::Model::Search
  include Tire::Model::Callbacks

  belongs_to :blog

  tire do
    # Dynamically construct the index name
    index_name Proc.new { |post| "tire-test-blog-#{post.blog_id}" }
    # You could also construct e.g. by date
    #index_name Proc.new { "tire-test-posts-#{Time.now.year}" }
    mapping do
      indexes :year, :type => 'integer'
      indexes :title, :type => 'string', :boost => 10
      indexes :body
    end
  end

  def to_indexed_json
    {
      :year => year,
      :title => title,
      :body  => body
    }.to_json
  end

end

### Create some data

blog1 = Blog.create(:title => "Hacking")
blog2 = Blog.create(:title => "Snowboarding")

post1a = Post.create(:blog => blog1, :year => 2009, :title => "Elasticsearch", :body => "It rulez.")
post1b = Post.create(:blog => blog1, :year => 2010, :title => "Tire", :body => "Awesome Ruby gem for ES.")
post2a = Post.create(:blog => blog2, :year => 2011, :title => "Elastic Carving", :body => "Carving in South Tyrolia.")

post1a.index.refresh
post2a.index.refresh

### Add alias

post1a.index.add_alias('tire-test-allposts')
post2a.index.add_alias('tire-test-allposts')

# Filtered index
post1a.index.aliases(  # should be a class method?!
  {:add => {
    :index => 'tire-test-blog-1', 
    :alias => 'tire-test-posts-2010', 
    :filter => {:term => {:year => 2010}}}},
  {:add => {
    :index => 'tire-test-blog-2', 
    :alias => 'tire-test-posts-2010', 
    :filter => {:term => {:year => 2010}}}},
  {:add => {
    :index => 'tire-test-blog-1', 
    :alias => 'tire-test-posts-2011', 
    :filter => {:term => {:year => 2011}}}},
  {:add => {
    :index => 'tire-test-blog-2', 
    :alias => 'tire-test-posts-2011', 
    :filter => {:term => {:year => 2011}}}})


### Search

puts "Post has a dynamic index name: #{Post.dynamic_index_name? ? 'ok' : 'error'}"

# Filter on blog 1 by alias
results = Post.search('elastic*', :index => 'tire-test-blog-1', :load => true)
puts "Search results: #{results.any? ? 'ok' : 'error'}"
puts "Should include post1a: #{results.include?(post1a) ? 'ok' : 'error'}"
puts "Should not include post2a: #{!results.include?(post2a) ? 'ok' : 'error'}"

# Filter on blog 2 by alias
results = Post.search('elastic*', :index => 'tire-test-blog-2', :load => true)
puts "Search results: #{results.any? ? 'ok' : 'error'}"
puts "Should not include post1a: #{!results.include?(post1a) ? 'ok' : 'error'}"
puts "Should include post2a: #{results.include?(post2a) ? 'ok' : 'error'}"

# Filter on all posts by alias
results = Post.search('elastic*', :index => 'tire-test-allposts', :load => true)
puts "Search results: #{results.any? ? 'ok' : 'error'}"
puts "Should include post1a: #{results.include?(post1a) ? 'ok' : 'error'}"
puts "Should include post2a: #{results.include?(post2a) ? 'ok' : 'error'}"

# Filter on posts from 2010
results = Post.search('*', :index => 'tire-test-posts-2010', :load => true)
puts "Search results: #{results.any? ? 'ok' : 'error'}"
puts "Should include post1b: #{results.include?(post1b) ? 'ok' : 'error'}"
puts "Should return only post1b: #{results.size == 1 ? 'ok' : 'error'}"

# Filter on posts from 2011
results = Post.search('*', :index => 'tire-test-posts-2011', :load => true)
puts "Search results: #{results.any? ? 'ok' : 'error'}"
puts "Should include post2a: #{results.include?(post2a) ? 'ok' : 'error'}"
puts "Should return only post2a: #{results.size == 1 ? 'ok' : 'error'}"


### Remove alias

post1a.index.add_alias('tire-test-allposts')
post2a.index.add_alias('tire-test-allposts')

