# ===================================================================================================================
# Template for generating a no-frills Rails application with support for ElasticSearch full-text search via Slingshot
# ===================================================================================================================
#
# This file creates a basic Rails application with support for ElasticSearch full-text via the Slingshot gem
#
# Run it like this:
#
#     rails new searchapp -m https://github.com/karmi/slingshot/raw/master/examples/rails-application-template.rb
#

run "rm public/index.html"
run "rm public/images/rails.png"
run "touch tmp/.gitignore log/.gitignore vendor/.gitignore"

git :init
git :add => '.'
git :commit => "-m 'Initial commit: Clean application'"

puts
say_status  "Rubygems", "Adding Rubygems into Gemfile...\n", :yellow
puts        '-'*80, ''

gem 'slingshot-rb', :git => 'https://github.com/karmi/slingshot.git', :branch => 'activemodel'
gem 'will_paginate', '~>3.0.pre'
git :add => '.'
git :commit => "-m 'Added gems'"

puts
say_status  "Rubygems", "Installing Rubygems...", :yellow

puts
puts "********************************************************************************"
puts "                Running `bundle install`. Let's watch a movie!"
puts "********************************************************************************", ""

run "bundle install"

puts
say_status  "Model", "Adding search support into the Article model...", :yellow
puts        '-'*80, ''

generate :scaffold, "Article title:string content:text published_on:date"
route "root :to => 'articles#index'"
rake  "db:migrate"

git :add => '.'
git :commit => "-m 'Added the Article resource'"

run "rm -f app/models/article.rb"
file 'app/models/article.rb', <<-CODE
class Article < ActiveRecord::Base
  include Slingshot::Model::Search
  include Slingshot::Model::Callbacks
end
CODE

initializer 'slingshot.rb', <<-CODE
Slingshot.configure do
  logger STDERR
end
CODE

git :commit => "-a -m 'Added Slingshot support into the Article class and an initializer'"

puts
say_status  "Controller", "Adding controller action, route, and neccessary HTML for search...", :yellow
puts        '-'*80, ''

gsub_file 'app/controllers/articles_controller.rb', %r{# GET /articles/1$}, <<-CODE
  # GET /articles/search
  def search
    @articles = Article.search params[:q]

    render :action => "index"
  end

  # GET /articles/1
CODE

gsub_file 'app/views/articles/index.html.erb', %r{<h1>Listing articles</h1>}, <<-CODE
<h1>Listing articles</h1>

<%= form_tag search_articles_path, :method => 'get' do %>
  <%= label_tag :query %>
  <%= text_field_tag :q, params[:q] %>
  <%= submit_tag :search %>
<% end %>

<hr>
CODE

gsub_file 'app/views/articles/index.html.erb', %r{<%= link_to 'New Article', new_article_path %>}, <<-CODE
<%= link_to 'New Article', new_article_path %>
<%= link_to 'Back', articles_path if params[:q] %>
CODE

gsub_file 'config/routes.rb', %r{resources :articles}, <<-CODE
  resources :articles do
    collection { get :search }
  end
CODE

git :commit => "-a -m 'Added Slingshot support into the frontend of application'"

puts
say_status  "Database", "Seeding the database with data...", :yellow
puts        '-'*80, ''

run "rm -f db/seeds.rb"
file 'db/seeds.rb', <<-CODE
contents = [
'Lorem ipsum dolor sit amet.',
'Consectetur adipisicing elit, sed do eiusmod tempor incididunt.',
'Labore et dolore magna aliqua.',
'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.',
'Excepteur sint occaecat cupidatat non proident.'
]

puts "Deleting all articles..."
Article.delete_all

puts "Creating articles:"
%w[ One Two Three Four Five ].each_with_index do |title, i|
  Article.create :title => title, :content => contents[i], :published_on => i.days.ago.utc
end
CODE

rake "db:seed"

git :add    => "db/seeds.rb"
git :commit => "-m 'Added database seeding script'"

puts
say_status  "Index", "Indexing database...", :yellow
puts        '-'*80, ''

rake "environment slingshot:import CLASS='Article' FORCE=true"

puts  "", "="*80
say_status  "DONE", "\e[1mStarting the application. Open http://localhost:3000 and search for something...\e[0m", :yellow
puts  "="*80, ""

run  "rails server"
