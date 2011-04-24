# **Slingshot** is a rich and comfortable Ruby client for the
# [_ElasticSearch_](http://www.elasticsearch.org/) search engine/database.
#
# It provides the API for the main _ElasticSearch_ features, and this document
# will walk you through them.
#
# <img src="http://github.com/favicon.ico" style="position:relative; top:2px">
# _Slingshot_ is open source, and you can download or clone the source code
# from <https://github.com/karmi/slingshot>.
#
# _ElasticSearch_ is a scalable, distributed, highly-available,
# RESTful database communicating by JSON over HTTP, based on [Lucene](http://lucene.apache.org/),
# written in Java. It manages to be very simple and very powerful at the same time.
#
# By following these instructions you should have the search running
# on a sane operation system in less then 10 minutes.

#### Installation

# Install Slingshot with Rubygems.
#
#     gem install slingshot-rb
#
require 'rubygems'
require 'slingshot'

#### Prerequisites

# You'll need a working and running _ElasticSearch_ server. Thankfully, that's easy.
( puts <<-"INSTALL" ; exit(1) ) unless RestClient.get('http://localhost:9200') rescue false
 [!] You don’t appear to have ElasticSearch installed. Please install and launch it with the following commands.
 curl -k -L -o elasticsearch-0.15.2.tar.gz http://github.com/downloads/elasticsearch/elasticsearch/elasticsearch-0.15.2.tar.gz
 tar -zxvf elasticsearch-0.15.2.tar.gz
 ./elasticsearch-0.15.2/bin/elasticsearch -f
INSTALL

### Storing and indexing documents

# Let's initialize an index named “articles”.
Slingshot.index 'articles' do
  # To make sure it's fresh, let's delete any existing index with the same name.
  delete
  # And then, let's create it.
  create

  # We want to store and index some articles with title and tags. Simple Hashes are OK.
  store :title => 'One',   :tags => ['ruby'],           :published_on => '2011-01-01'
  store :title => 'Two',   :tags => ['ruby', 'python'], :published_on => '2011-01-02'
  store :title => 'Three', :tags => ['java'],           :published_on => '2011-01-02'
  store :title => 'Four',  :tags => ['ruby', 'php'],    :published_on => '2011-01-03'

  # We force refreshing the index, so we can query it immediately.
  refresh
end

# We may want to define a specific [mapping](http://www.elasticsearch.org/guide/reference/api/admin-indices-create-index.html)
# for the index.

Slingshot.index 'articles' do
  # To do so, just pass a Hash containing the specified mapping to the `Index#create` method.
  create :mappings => {
    # Specify for which type of documents this mapping should be used (`article` in this case).
    :article => {
      :properties => {
        # Specify the type of the field, whether it should be analyzed, etc.
        :id       => { :type => 'string', :index => 'not_analyzed', :include_in_all => false },
        # Set the boost or analyzer settings for the field, et cetera. The _ElasticSearch_ guide
        # has [more information](http://elasticsearch.org/guide/reference/mapping/index.html).
        :title    => { :type => 'string', :boost => 2.0,            :analyzer => 'snowball'  },
        :tags     => { :type => 'string', :analyzer => 'keyword'                             },
        :content  => { :type => 'string', :analyzer => 'snowball'                            }
      }
    }
  }
end



### Searching

# With the documents indexed and stored in the _ElasticSearch_ database, we want to search for them.
#
# Slingshot exposes the search interface via simple domain-specific language.


#### Simple Query String Searches

# We can do simple searches, like searching for articles containing “One” in their title.
s = Slingshot.search('articles') do
  query do
    string "title:One"
  end
end

# The results:
#     * One [tags: ruby]
s.results.each do |document|
  puts "* #{ document.title } [tags: #{document.tags.join(', ')}]"
end

# Of course, we may write the blocks in shorter notation.

# Let's search for articles whose titles begin with letter “T”.
s = Slingshot.search('articles') { query { string "title:T*" } }

# The results:
#     * Two [tags: ruby, python]
#     * Three [tags: java]
s.results.each do |document|
  puts "* #{ document.title } [tags: #{document.tags.join(', ')}]"
end

# We can use any valid [Lucene query syntax](http://lucene.apache.org/java/3_0_3/queryparsersyntax.html)
# for the query string queries.

# For debugging, we can display the JSON which is being sent to _ElasticSearch_.
#
#     {"query":{"query_string":{"query":"title:T*"}}}
#
puts "", "Query:", "-"*80
puts s.to_json

# Or better, we may display a complete `curl` command, so we can execute it in terminal
# to see the raw output, tweak params and debug any problems.
#
#     curl -X POST "http://localhost:9200/articles/_search?pretty=true" \
#          -d '{"query":{"query_string":{"query":"title:T*"}}}'
#
puts "", "Try the query in Curl:", "-"*80
puts s.to_curl


### Logging

# For debugging more complex situations, you can enable logging, so requests and responses
# will be logged using the `curl`-based format.

Slingshot.configure do

  # By default, at the _info_ level, only the `curl`-format of request and
  # basic information about the response will be logged:
  #
  #     # 2011-04-24 11:34:01:150 [CREATE] ("articles")
  #     #
  #     curl -X POST "http://localhost:9200/articles" -d '{
  #     
  #     }'
  #     
  #     # 2011-04-24 11:34:01:152 [200]
  #
  logger 'elasticsearch.log'

  # For debugging, you can switch to the _debug_ level, which will log the complete JSON responses.
  #
  # That's very convenient if you want to post a recreation of some problem or solution to the mailing list, IRC, etc.
  #
  logger 'elasticsearch.log', :level => 'debug'

  # Note that you can pass any [`IO`](http://www.ruby-doc.org/core/classes/IO.html)-compatible Ruby object as a logging device.
  #
  logger STDERR
end

### Configuration

# As you have just seen with logging, you can configure various parts of _Slingshot_.

Slingshot.configure do

  # First of all, you can configure the URL for _ElasticSearch_.
  url "http://search.example.com"

  # Second, you may want to wrap the results in your own class.
  class MySpecialWrapper; end
  wrapper MySpecialWrapper

  # Of course, you can reset one or all configuration settings to their defaults.
  reset

end


### Complex Searching

#### Other Types of Queries

# Query strings are convenient for simple searches, but we may want to define our queries more expressively,
# using the _ElasticSearch_ Query DSL.
#
# Let's suppose we want to search for articles with specific _tags_, in our case “ruby” _or_ “python”.
#
# That's a great excuse to use a [_terms_](http://elasticsearch.org/guide/reference/query-dsl/terms-query.html)
# query.
s = Slingshot.search('articles') do
  query do
    terms :tags, ['ruby', 'python']
  end
end

# The search, as expected, returns three articles, all tagged “ruby” — among other tags:
#
#     * Two [tags: ruby, python]
#     * One [tags: ruby]
#     * Four [tags: ruby, php]
s.results.each do |document|
  puts "* #{ document.title } [tags: #{document.tags.join(', ')}]"
end

# What if we wanted to search for articles tagged both “ruby” _and_ “python”.
# That's a great excuse to specify `minimum_match` for the query.
s = Slingshot.search('articles') do
  query do
    terms :tags, ['ruby', 'python'], :minimum_match => 2
  end
end

# The search, as expected, returns one article, tagged with _both_ “ruby” and “python”:
#
#     * Two [tags: ruby, python]
s.results.each do |document|
  puts "* #{ document.title } [tags: #{document.tags.join(', ')}]"
end

# _ElasticSearch_ supports many types of [queries](http://www.elasticsearch.org/guide/reference/query-dsl/).
#
# Eventually, _Slingshot_ will support all of them.
# So far, only these are supported:
#
# * [string](http://www.elasticsearch.org/guide/reference/query-dsl/query-string-query.html)
# * [term](http://elasticsearch.org/guide/reference/query-dsl/term-query.html)
# * [terms](http://elasticsearch.org/guide/reference/query-dsl/terms-query.html)
# * [all](http://www.elasticsearch.org/guide/reference/query-dsl/match-all-query.html)

#### Faceted Search

# _ElasticSearch_ makes it trivial to retrieve complex aggregated data from our index/database,
# so called [_facets_](http://www.elasticsearch.org/guide/reference/api/search/facets/index.html).

# Let's say we want to display article counts for every tag in the database.
# For that, we'll use a _terms_ facet.

#
s = Slingshot.search 'articles' do
  # We will search for articles whose title begins with letter “T”,
  query { string 'title:T*' }

  # and retrieve their counts, “bucketed” by their `tags`.
  facet 'tags' do
    terms :tags
  end
end

# As we see, our query has found two articles, and if you recall our articles from above,
# _Two_ is tagged with “ruby” and “python”, _Three_ is tagged with “java”. So the counts
# won't surprise us:
#     Found 2 articles: Three, Two
#     Counts:
#     -------
#     ruby       1
#     python     1
#     java       1
puts "Found #{s.results.count} articles: #{s.results.map(&:title).join(', ')}"
puts "Counts based on tags:", "-"*25
s.results.facets['tags']['terms'].each do |f|
  puts "#{f['term'].ljust(10)} #{f['count']}"
end

# These counts are based on the scope of our current query (called `main` in _ElasticSearch_).
# What if we wanted to display aggregated counts by `tags` across the whole database?

#
s = Slingshot.search 'articles' do
  query { string 'title:T*' }

  facet 'global-tags' do
    # That's where the `global` scope for a facet comes in.
    terms :tags, :global => true
  end

  # As you can see, we can even combine facets scoped to the current query
  # with global facets — we'll just use a different name.
  facet 'current-tags' do
    terms :tags
  end
end

# Aggregated results for the current query are the same as previously:
#     Current query facets:
#     -------------------------
#     ruby       1
#     python     1
#     java       1
puts "Current query facets:", "-"*25
s.results.facets['current-tags']['terms'].each do |f|
  puts "#{f['term'].ljust(10)} #{f['count']}"
end

# As we see, aggregated results for the global scope include also
# tags for articles not matched by the query, such as “java” or “php”:
#     Global facets:
#     -------------------------
#     ruby       3
#     python     1
#     php        1
#     java       1
puts "Global facets:", "-"*25
s.results.facets['global-tags']['terms'].each do |f|
  puts "#{f['term'].ljust(10)} #{f['count']}"
end

# _ElasticSearch_ supports many types of advanced facets.
#
# Eventually, _Slingshot_ will support all of them.
# So far, only these are supported:
#
# * [terms](http://www.elasticsearch.org/guide/reference/api/search/facets/terms-facet.html)
# * [date](http://www.elasticsearch.org/guide/reference/api/search/facets/date-histogram-facet.html)

# The real power of facets lies in their combination with
# [filters](http://elasticsearch.org/guide/reference/api/search/filter.html).

# Filters enable us to restrict the returned documents, for example to a specific category,
# but to calculate the facet counts based on the original query.
# The immediate use case for that is the „faceted navigation“.


#### Filtered Search

# So, let's make our search a bit more complex. Let's search for articles whose titles begin
# with letter “T”, again, but filter the results, so only the articles tagged “ruby”
# are returned.
s = Slingshot.search 'articles' do
  
  # We use the same **query** as before.
  query { string 'title:T*' } 

  # And add a _terms_ **filter** based on tags.
  filter :terms, :tags => ['ruby']

  # And, of course, our facet definition.
  facet('tags') { terms :tags }

end

# We see that only the article _Two_ (tagged “ruby” and “python”) was returned,
# _not_ the article _Three_ (tagged “java”):
#
#     * Two [tags: ruby, python]
s.results.each do |document|
  puts "* #{ document.title } [tags: #{document.tags.join(', ')}]"
end

# However, count for article _Three_'s tags, “java”, _is_ in fact included in facets:
#
#     Counts based on tags:
#     -------------------------
#     ruby       1
#     python     1
#     java       1
puts "Counts based on tags:", "-"*25
s.results.facets['tags']['terms'].each do |f|
  puts "#{f['term'].ljust(10)} #{f['count']}"
end


#### Sorting

# By default, the results are sorted according to their relevancy
# (available as the `_score` property).

# But, what if we want to sort the results based on some other criteria,
# such as published date or product price? We can do that.
s = Slingshot.search 'articles' do
  # We search for articles tagged “ruby”.
  query { string 'tags:ruby' } 

   # And sort them by their `title`, in descending order.
  sort { title 'desc' }
end

# The results:
#     * Two
#     * One
#     * Four
s.results.each do |document|
  puts "* #{ document.title }"
end

# Of course, it's possible to combine more fields in the sorting definition.

s = Slingshot.search 'articles' do
  # We will just get all articles for this case.
  query { all } 

  sort do
    # We will sort the results by their `published_on` property in ascending (default) order,
    published_on
    # and by their `title` property, in descending order.
    title 'desc'
  end
end

# The results:
#     * One         (Published on: 2011-01-01)
#     * Two         (Published on: 2011-01-02)
#     * Three       (Published on: 2011-01-02)
#     * Four        (Published on: 2011-01-03)
s.results.each do |document|
  puts "* #{ document.title.ljust(10) }  (Published on: #{ document.published_on })"
end

#### Highlighting

# Often, you want to highlight the snippets matching your query in the
# displayed results.
# _ElasticSearch_ provides rich
# [highlighting](http://www.elasticsearch.org/guide/reference/api/search/highlighting.html)
# features, and Slingshot makes them trivial to use.
#
# Let's suppose that we want to highlight terms of our query.
#
s = Slingshot.search 'articles' do
  # Let's search for documents containing word “Two” in their titles,
  query { string 'title:Two' } 

   # and instruct _ElasticSearch_ to highlight relevant snippets.
  highlight :title
end

# The results:
#     Title: Two, highlighted title: <em>Two</em>
s.results.each do |document|
  puts "Title: #{ document.title }, highlighted title: #{document.highlight.title}"
end

# We can configure many options for highlighting, such as:
#
s = Slingshot.search 'articles' do
  query { string 'title:Two' }

  # • specifying the fields to highlight
  highlight :title, :body

  # • specifying their options
  highlight :title, :body => { :number_of_fragments => 0 }

  # • or specifying global highlighting options, such as the wrapper tag
  highlight :title, :body, :options => { :tag => '<strong class="highlight">' }
end



### What's next?

# As you can see, [_Slingshot_](https://github.com/karmi/slingshot) supports the
# main features of _ElasticSearch_ in Ruby.
#
# It allows you to create and delete indices, add documents, search them, retrieve facets, highlight the results,
# and comes with usable logging facility.
#
# Of course, the holy grail of any search library is easy, painless integration with your Ruby classes, and,
# most importantly, with ActiveRecord/ActiveModel classes.
#
# _Slingshot_ already provides such integration, though in experimental mode.
# Check out the tests in the
# [`activemodel`](https://github.com/karmi/slingshot/blob/activemodel/test/integration/active_model_searchable_test.rb) branch.
#
# Send any feedback via Github issues, or ask questions in the [#elasticsearch](irc://irc.freenode.net/#elasticsearch) IRC channel.
