$LOAD_PATH << File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'rubygems'
require 'active_record'
require 'yajl/json_gem'
require 'tire'

### Remove existing indexes

%w(tire-test-allposts tire-test-blog-1 tire-test-blog-2).each do |index_name|
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
      indexes :title, :type => 'string', :boost => 10
      indexes :body
    end
  end

  def to_indexed_json
    {
      :title => title,
      :body  => body
    }.to_json
  end

end

### Create some data

blog1 = Blog.create(:title => "Hacking")
blog2 = Blog.create(:title => "Snowboarding")

post1a = Post.create(:blog => blog1, :title => "Elasticsearch", :body => "It rulez.")
post1b = Post.create(:blog => blog1, :title => "Tire", :body => "Awesome Ruby gem for ES.")

post2a = Post.create(:blog => blog2, :title => "Elastic Carving", :body => "Carving in South Tyrolia.")

post1a.index.refresh
post2a.index.refresh


### Search

puts "Post has a dynamic index name: #{Post.dynamic_index_name? ? 'ok' : 'error'}"

results = Post.search('elastic*', :index => 'tire-test-blog-1', :load => true)
puts "Search results: #{results.any? ? 'ok' : 'error'}"
puts "Should include post1a: #{results.include?(post1a) ? 'ok' : 'error'}"
puts "Search not include post2a: #{!results.include?(post2a) ? 'ok' : 'error'}"

results = Post.search('elastic*', :index => 'tire-test-blog-2', :load => true)
puts "Search results: #{results.any? ? 'ok' : 'error'}"
puts "Search not include post1a: #{!results.include?(post1a) ? 'ok' : 'error'}"
puts "Search include post2a: #{results.include?(post2a) ? 'ok' : 'error'}"


