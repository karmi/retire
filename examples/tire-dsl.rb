# encoding: UTF-8
#
# **Tire** provides rich and comfortable Ruby API for the
# [_Elasticsearch_](http://www.elasticsearch.org/) search engine/database.
#
# _Elasticsearch_ is a scalable, distributed, cloud-ready, highly-available
# full-text search engine and database, communicating by JSON over RESTful HTTP,
# based on [Lucene](http://lucene.apache.org/), written in Java.
#
# <img src="http://github.com/favicon.ico" style="position:relative; top:2px">
# _Tire_ is open source, and you can download or clone the source code
# from <https://github.com/karmi/tire>.
#
# By following these instructions you should have the search running
# on a sane operating system in less then 10 minutes.

# Note, that this file can be executed directly:
#
#     ruby -I lib examples/tire-dsl.rb
#


#### Installation

# Install _Tire_ with _Rubygems_:

#
#     gem install tire
#
require 'rubygems'

# _Tire_ uses the [_multi_json_](https://github.com/intridea/multi_json) gem as a generic JSON library.
# We want to use the [_yajl-ruby_](https://github.com/brianmario/yajl-ruby) gem in its full on mode here.
#
require 'yajl/json_gem'

# Now, let's require the _Tire_ gem itself, and we're ready to go.
#
require 'tire'

#### Prerequisites

# We'll need a working and running _Elasticsearch_ server, of course. Thankfully, that's easy.
( puts <<-"INSTALL" ; exit(1) ) unless (RestClient.get('http://localhost:9200') rescue false)

 [ERROR] You don’t appear to have Elasticsearch installed. Please install and launch it with the following commands:

 curl -k -L -o elasticsearch-0.20.2.tar.gz http://github.com/downloads/elasticsearch/elasticsearch/elasticsearch-0.20.2.tar.gz
 tar -zxvf elasticsearch-0.20.2.tar.gz
 ./elasticsearch-0.20.2/bin/elasticsearch -f
INSTALL

### Storing and indexing documents

# Let's initialize an index named “articles”.
#
Tire.index 'articles' do
  # To make sure it's fresh, let's delete any existing index with the same name.
  #
  delete
  # And then, let's create it.
  #
  create

  # We want to store and index some articles with `title`, `tags` and `published_on` properties.
  # Simple Hashes are OK. The default type is „document”.
  #
  store :title => 'One',   :tags => ['ruby'],           :published_on => '2011-01-01'
  store :title => 'Two',   :tags => ['ruby', 'python'], :published_on => '2011-01-02'

  # We usually want to set a specific _type_ for the document in _Elasticsearch_.
  # Simply setting a `type` property is OK.
  #
  store :type => 'article',
        :title => 'Three',
        :tags => ['java'],
        :published_on => '2011-01-02'

  # We may want to wrap your data in a Ruby class, and use it when storing data.
  # The contract required of such a class is very simple.
  #
  class Article

    #
    attr_reader :title, :tags, :published_on
    def initialize(attributes={})
      @attributes =  attributes
      @attributes.each_pair { |name,value| instance_variable_set :"@#{name}", value }
    end

    # It must provide a `type`, `_type` or `document_type` method for propper mapping.
    #
    def type
      'article'
    end

    # And it must provide a `to_indexed_json` method for conversion to JSON.
    #
    def to_indexed_json
      @attributes.to_json
    end
  end

  # Note: Since our class takes a Hash of attributes on initialization, we may even
  # wrap the results in instances of this class; we'll see how to do that further below.
  #
  article = Article.new :title => 'Four',
                        :tags => ['ruby', 'php'],
                        :published_on => '2011-01-03'

  # Let's store the `article`, now.
  #
  store article

  # And let's „force refresh“ the index, so we can query it immediately.
  #
  refresh
end

# We may want to define a specific [mapping](http://www.elasticsearch.org/guide/reference/api/admin-indices-create-index.html)
# for the index.

Tire.index 'articles' do
  delete

  # To do so, let's just pass a Hash containing the specified mapping to the `Index#create` method.
  #
  create :mappings => {

    # Let's specify for which _type_ of documents this mapping should be used:
    # „article”, in our case.
    #
    :article => {
      :properties => {

        # Let's specify the type of the field, whether it should be analyzed, ...
        #
        :id       => { :type => 'string', :index => 'not_analyzed', :include_in_all => false },

        # ... set the boost or analyzer settings for the field, etc. The _Elasticsearch_ guide
        # has [more information](http://elasticsearch.org/guide/reference/mapping/index.html).
        # Don't forget, that proper mapping is key to efficient and effective search.
        # But don't fret about getting the mapping right the first time, you won't.
        # In most cases, the default, dynamic mapping is just fine for prototyping.
        #
        :title    => { :type => 'string', :analyzer => 'snowball', :boost => 2.0             },
        :tags     => { :type => 'string', :analyzer => 'keyword'                             },
        :content  => { :type => 'string', :analyzer => 'czech'                               }
      }
    }
  }
end

#### Bulk Indexing

# Of course, we may have large amounts of data, and adding them to the index one by one really isn't the best idea.
# We can use _Elasticsearch's_ [bulk API](http://www.elasticsearch.org/guide/reference/api/bulk.html)
# for importing the data.

# So, for demonstration purposes, let's suppose we have a simple collection of hashes to store.
#
articles = [

  # Notice that such objects must have an `id` property!
  #
  { :id => '1', :type => 'article', :title => 'one',   :tags => ['ruby'],           :published_on => '2011-01-01' },

  # And, of course, they should contain the `type` property for the mapping to work!
  #
  { :id => '2', :type => 'article', :title => 'two',   :tags => ['ruby', 'python'], :published_on => '2011-01-02' },
  { :id => '3', :type => 'article', :title => 'three', :tags => ['java'],           :published_on => '2011-01-02' },
  { :id => '4', :type => 'article', :title => 'four',  :tags => ['ruby', 'php'],    :published_on => '2011-01-03' }
]

# We can just push them into the index in one go.
#
Tire.index 'articles' do
  import articles
end

# Of course, we can easily manipulate the documents before storing them in the index.
#
Tire.index 'articles' do
  # ... by passing a block to the `import` method. The collection will
  # be available in the block argument.
  #
  import articles do |documents|

    # We will capitalize every _title_ and return the manipulated collection
    # back to the `import` method.
    #
    documents.map { |document| document.update(:title => document[:title].capitalize) }
  end

  refresh
end

### Searching

# With the documents indexed and stored in the _Elasticsearch_ database, we can search them, finally.
#
# _Tire_ exposes the search interface via simple domain-specific language.

#### Simple Query String Searches

# We can do simple searches, like searching for articles containing “One” in their title.
#
s = Tire.search('articles') do
  query do
    string "title:one"
  end
end

# The results:
#     * One [tags: ruby]
#
s.results.each do |document|
  puts "* #{ document.title } [tags: #{document.tags.join(', ')}]"
end

# Or, we can search for articles published between January, 1st and January, 2nd.
#
s = Tire.search('articles') do
  query do
    string "published_on:[2011-01-01 TO 2011-01-02]"
  end
end

# The results:
#     * One [published: 2011-01-01]
#     * Two [published: 2011-01-02]
#     * Three [published: 2011-01-02]
#
s.results.each do |document|
  puts "* #{ document.title } [published: #{document.published_on}]"
end

# Notice, that we can access local variables from the _enclosing scope_.
# (Of course, we may write the blocks in shorter notation.)

# We will define the query in a local variable named `q`...
#
q = "title:T*"
# ... and we can use it inside the `query` block.
#
s = Tire.search('articles') { query { string q } }

# The results:
#     * Two [tags: ruby, python]
#     * Three [tags: java]
#
s.results.each do |document|
  puts "* #{ document.title } [tags: #{document.tags.join(', ')}]"
end

# Often, we need to access variables or methods defined in the _outer scope_.
# To do that, we have to use a slight variation of the DSL.
#

# Let's assume we have a plain Ruby class, named `Article`.
#
class Article

  # We will define the query in a class method...
  #
  def self.q
    "title:T*"
  end

  # ... and wrap the _Tire_ search method in another one.
  def self.search

    # Notice how we pass the `search` object around as a block argument.
    #
    Tire.search('articles') do |search|

      # And we pass the query object in a similar matter.
      #
      search.query do |query|

        # Which means we can access the `q` class method.
        #
        query.string self.q
      end
    end.results
  end
end

# We may use any valid [Lucene query syntax](http://lucene.apache.org/java/3_0_3/queryparsersyntax.html)
# for the `query_string` queries.

# For debugging our queries, we can display the JSON which is being sent to _Elasticsearch_.
#
#     {"query":{"query_string":{"query":"title:T*"}}}
#
puts "", "Query:", "-"*80
puts s.to_json

# Or better yet, we may display a complete `curl` command to recreate the request in terminal,
# so we can see the naked response, tweak request parameters and meditate on problems.
#
#     curl -X POST "http://localhost:9200/articles/_search?pretty=true" \
#          -d '{"query":{"query_string":{"query":"title:T*"}}}'
#
puts "", "Try the query in Curl:", "-"*80
puts s.to_curl


### Logging

# For debugging more complex situations, we can enable logging, so requests and responses
# will be logged using this `curl`-friendly format.

Tire.configure do

  # By default, at the _info_ level, only the `curl`-format of request and
  # basic information about the response will be logged:
  #
  #     # 2011-04-24 11:34:01:150 [CREATE] ("articles")
  #     #
  #     curl -X POST "http://localhost:9200/articles"
  #
  #     # 2011-04-24 11:34:01:152 [200]
  #
  logger 'elasticsearch.log'

  # For debugging, we can switch to the _debug_ level, which will log the complete JSON responses.
  #
  # That's very convenient if we want to post a recreation of some problem or solution
  # to the mailing list, IRC channel, etc.
  #
  logger 'elasticsearch.log', :level => 'debug'

  # Note that we can pass any [`IO`](http://www.ruby-doc.org/core/classes/IO.html)-compatible Ruby object as a logging device.
  #
  logger STDERR
end

### Configuration

# As we have just seen with logging, we can configure various parts of _Tire_.
#
Tire.configure do

  # First of all, we can configure the URL for _Elasticsearch_.
  #
  url "http://search.example.com"

  # Second, we may want to wrap the result items in our own class, for instance
  # the `Article` class set above.
  #
  wrapper Article

  # Finally, we can reset one or all configuration settings to their defaults.
  #
  reset :url
  reset

end


### Complex Searching

# Query strings are convenient for simple searches, but we may want to define our queries more expressively,
# using the _Elasticsearch_ [Query DSL](http://www.elasticsearch.org/guide/reference/query-dsl/index.html).
#
s = Tire.search('articles') do

  # Let's suppose we want to search for articles with specific _tags_, in our case “ruby” _or_ “python”.
  #
  query do

    # That's a great excuse to use a [_terms_](http://elasticsearch.org/guide/reference/query-dsl/terms-query.html)
    # query.
    #
    terms :tags, ['ruby', 'python']
  end
end

# The search, as expected, returns three articles, all tagged “ruby” — among other tags:
#
#     * Two [tags: ruby, python]
#     * One [tags: ruby]
#     * Four [tags: ruby, php]
#
s.results.each do |document|
  puts "* #{ document.title } [tags: #{document.tags.join(', ')}]"
end

# What if we wanted to search for articles tagged both “ruby” _and_ “python”?
#
s = Tire.search('articles') do
  query do

    # That's a great excuse to specify `minimum_match` for the query.
    #
    terms :tags, ['ruby', 'python'], :minimum_match => 2
  end
end

# The search, as expected, returns one article, tagged with _both_ “ruby” and “python”:
#
#     * Two [tags: ruby, python]
#
s.results.each do |document|
  puts "* #{ document.title } [tags: #{document.tags.join(', ')}]"
end

#### Boolean Queries

# Quite often, we need complex queries with boolean logic.
# Instead of composing long query strings such as `tags:ruby OR tags:java AND NOT tags:python`,
# we can use the [_bool_](http://www.elasticsearch.org/guide/reference/query-dsl/bool-query.html)
# query.

s = Tire.search('articles') do
  query do

    # In _Tire_, we can build `bool` queries declaratively, as usual.
    boolean do

      # Let's define a `should` (`OR`) query for _ruby_,
      #
      should   { string 'tags:ruby' }

      # as well as for _java_,
      should   { string 'tags:java' }

      # while defining a `must_not` (`AND NOT`) query for _python_.
      must_not { string 'tags:python' }
    end
  end
end

# The search returns these documents:
#
#     * One [tags: ruby]
#     * Three [tags: java]
#     * Four [tags: ruby, php]
#
s.results.each do |document|
  puts "* #{ document.title } [tags: #{document.tags.join(', ')}]"
end

# The best thing about `boolean` queries is that we can very easily save these partial queries as Ruby blocks,
# to mix and reuse them later, since we can call the `boolean` method multiple times.
#

# Let's define the query for the _tags_ property,
#
tags_query = lambda do |boolean|
  boolean.should { string 'tags:ruby' }
  boolean.should { string 'tags:java' }
end

# ... and a query for the _published_on_ property.
published_on_query = lambda do |boolean|
  boolean.must   { string 'published_on:[2011-01-01 TO 2011-01-02]' }
end

# Now, we can use the `tags_query` on its own.
#
Tire.search('articles') { query { boolean &tags_query } }

# Or, we can combine it with the `published_on` query.
#
Tire.search('articles') do
  query do
    boolean &tags_query
    boolean &published_on_query
  end
end

# _Elasticsearch_ supports many types of [queries](http://www.elasticsearch.org/guide/reference/query-dsl/).
#
# Eventually, _Tire_ will support all of them. So far, only these are supported:
#
# * [string](http://www.elasticsearch.org/guide/reference/query-dsl/query-string-query.html)
# * [text](http://www.elasticsearch.org/guide/reference/query-dsl/text-query.html)
# * [term](http://elasticsearch.org/guide/reference/query-dsl/term-query.html)
# * [terms](http://elasticsearch.org/guide/reference/query-dsl/terms-query.html)
# * [bool](http://www.elasticsearch.org/guide/reference/query-dsl/bool-query.html)
# * [custom_score](http://www.elasticsearch.org/guide/reference/query-dsl/custom-score-query.html)
# * [fuzzy](http://www.elasticsearch.org/guide/reference/query-dsl/fuzzy-query.html)
# * [all](http://www.elasticsearch.org/guide/reference/query-dsl/match-all-query.html)
# * [ids](http://www.elasticsearch.org/guide/reference/query-dsl/ids-query.html)

#### Faceted Search

# _Elasticsearch_ makes it trivial to retrieve complex aggregated data from our index/database,
# so called [_facets_](http://www.elasticsearch.org/guide/reference/api/search/facets/index.html).

# Let's say we want to display article counts for every tag in the database.
# For that, we'll use a _terms_ facet.

#
s = Tire.search 'articles' do

  # We will search for articles whose title begins with letter “T”,
  #
  query { string 'title:T*' }

  # and retrieve the counts “bucketed” by `tags`.
  #
  facet 'tags' do
    terms :tags
  end
end

# As we see, our query has found two articles, and if you recall our articles from above,
# _Two_ is tagged with “ruby” and “python”, while _Three_ is tagged with “java”.
#
#     Found 2 articles: Three, Two
#
# The counts shouldn't surprise us:
#
#     Counts by tag:
#     -------------------------
#     ruby       1
#     python     1
#     java       1
#
puts "Found #{s.results.count} articles: #{s.results.map(&:title).join(', ')}"
puts "Counts by tag:", "-"*25
s.results.facets['tags']['terms'].each do |f|
  puts "#{f['term'].ljust(10)} #{f['count']}"
end

# These counts are based on the scope of our current query.
# What if we wanted to display aggregated counts by `tags` across the whole database?

#
s = Tire.search 'articles' do

  # Let's repeat the search for “T”...
  #
  query { string 'title:T*' }

  facet 'global-tags', :global => true do

    # ...but set the `global` scope for the facet in this case.
    #
    terms :tags
  end

  # We can even _combine_ facets scoped to the current query
  # with globally scoped facets — we'll just use a different name.
  #
  facet 'current-tags' do
    terms :tags
  end
end

# Aggregated results for the current query are the same as previously:
#
#     Current query facets:
#     -------------------------
#     ruby       1
#     python     1
#     java       1
#
puts "Current query facets:", "-"*25
s.results.facets['current-tags']['terms'].each do |f|
  puts "#{f['term'].ljust(10)} #{f['count']}"
end

# On the other hand, aggregated results for the global scope include also
# tags for articles not matched by the query, such as “java” or “php”:
#
#     Global facets:
#     -------------------------
#     ruby       3
#     python     1
#     php        1
#     java       1
#
puts "Global facets:", "-"*25
s.results.facets['global-tags']['terms'].each do |f|
  puts "#{f['term'].ljust(10)} #{f['count']}"
end

# _Elasticsearch_ supports many advanced types of facets, such as those for computing statistics or geographical distance.
#
# Eventually, _Tire_ will support all of them. So far, only these are supported:
#
# * [terms](http://www.elasticsearch.org/guide/reference/api/search/facets/terms-facet.html)
# * [date](http://www.elasticsearch.org/guide/reference/api/search/facets/date-histogram-facet.html)
# * [range](http://www.elasticsearch.org/guide/reference/api/search/facets/range-facet.html)
# * [histogram](http://www.elasticsearch.org/guide/reference/api/search/facets/histogram-facet.html)
# * [statistical](http://www.elasticsearch.org/guide/reference/api/search/facets/statistical-facet.html)
# * [terms_stats](http://www.elasticsearch.org/guide/reference/api/search/facets/terms-stats-facet.html)
# * [query](http://www.elasticsearch.org/guide/reference/api/search/facets/query-facet.html)

# We have seen that _Elasticsearch_ facets enable us to fetch complex aggregations from our data.
#
# They are frequently used for another feature, „faceted navigation“.
# We can be combine query and facets with
# [filters](http://elasticsearch.org/guide/reference/api/search/filter.html),
# so the returned documents are restricted by certain criteria — for example to a specific category —,
# but the aggregation calculations are still based on the original query.


#### Filtered Search

# So, let's make our search a bit more complex. Let's search for articles whose titles begin
# with letter “T”, again, but filter the results, so only the articles tagged “ruby”
# are returned.
#
s = Tire.search 'articles' do

  # We will use just the same **query** as before.
  #
  query { string 'title:T*' }

  # But we will add a _terms_ **filter** based on tags.
  #
  filter :terms, :tags => ['ruby']

  # And, of course, our facet definition.
  #
  facet('tags') { terms :tags }

end

# We see that only the article _Two_ (tagged “ruby” and “python”) is returned,
# _not_ the article _Three_ (tagged “java”):
#
#     * Two [tags: ruby, python]
#
s.results.each do |document|
  puts "* #{ document.title } [tags: #{document.tags.join(', ')}]"
end

# The _count_ for article _Three_'s tags, “java”, on the other hand, _is_ in fact included:
#
#     Counts by tag:
#     -------------------------
#     ruby       1
#     python     1
#     java       1
#
puts "Counts by tag:", "-"*25
s.results.facets['tags']['terms'].each do |f|
  puts "#{f['term'].ljust(10)} #{f['count']}"
end

#### Sorting

# By default, the results are sorted according to their relevancy.
#
s = Tire.search('articles') { query { string 'tags:ruby' } }

s.results.each do |document|
  puts "* #{ document.title } " +
       "[tags: #{document.tags.join(', ')}; " +

       # The score is available as the `_score` property.
       #
       "score: #{document._score}]"
end

# The results:
#
#     * One [tags: ruby; score: 0.30685282]
#     * Four [tags: ruby, php; score: 0.19178301]
#     * Two [tags: ruby, python; score: 0.19178301]

# But, what if we want to sort the results based on some other criteria,
# such as published date or product price? We can do that.
#
s = Tire.search 'articles' do

  # We will search for articles tagged “ruby”, again, ...
  #
  query { string 'tags:ruby' }

   # ... but will sort them by their `title`, in descending order.
   #
  sort { by :title, 'desc' }
end

# The results:
#
#     * Two
#     * One
#     * Four
#
s.results.each do |document|
  puts "* #{ document.title }"
end

# Of course, it's possible to combine more fields in the sorting definition.

s = Tire.search 'articles' do

  # We will just get all articles in this case.
  #
  query { all }

  sort do

    # We will sort the results by their `published_on` property in _ascending_ order (the default),
    #
    by :published_on

    # and by their `title` property, in _descending_ order.
    #
    by :title, 'desc'
  end
end

# The results:
#
#     * One         (Published on: 2011-01-01)
#     * Two         (Published on: 2011-01-02)
#     * Three       (Published on: 2011-01-02)
#     * Four        (Published on: 2011-01-03)
#
s.results.each do |document|
  puts "* #{ document.title.ljust(10) }  (Published on: #{ document.published_on })"
end

#### Nested Documents and Queries

# Often, we want to store more complex entities in _Elasticsearch_;
# for example, we may want to store the information about comments for each article,
# and then search for articles where a certain person left a certain note.

# In the simplest case, we can store the comments as an Array of JSON documents in the
# article document. If we do that naively, our search results will be incorrect, though.
# That's because a match in just one field will be enough to match a document.
# We need to query parts of the document as if they were separate entities.

# _Elasticsearch_ provides a specific `nested`
# [field type](http://www.elasticsearch.org/guide/reference/mapping/nested-type.html) and
# [query](http://www.elasticsearch.org/guide/reference/query-dsl/nested-query.html)
# for working with "embedded" documents like these.

# So, let's update the mapping for the index first, adding the `comments` property as a `nested` type:
#
Tire::Configuration.client.put Tire.index('articles').url+'/article/_mapping',
                               { :article => { :properties => { :comments => { :type => 'nested' } } } }.to_json

# And let's add comments to articles (notice that both articles contain a comment with the _Cool!_ message,
# though by different authors):
#
Tire.index 'articles' do
  update :article, 1,
         :doc => { :comments => [ { :author => 'John', :message => 'Great!' }, { :author => 'Bob', :message => 'Cool!' } ]   }
  update :article, 2,
         :doc => { :comments => [ { :author => 'John', :message => 'Cool!' }, { :author => 'Mary', :message => 'Thanks!' } ] }
  refresh
end

# We'll use the `nested` query to search for articles where _John_ left a _"Cool"_ message:
#
s = Tire.search 'articles' do
  query do
    nested :path => 'comments' do
      query do
        match 'comments.author',  'John'
        match 'comments.message', 'cool'
      end
    end
  end
end

# The results contain just the second document, correctly:
#
#     * Two (comments: 2)
#
s.results.each do |document|
  puts "* #{ document.title } (comments: #{document.comments.size})"
end


#### Highlighting

# Often, we want to highlight the snippets matching our query in the displayed results.
# _Elasticsearch_ provides rich
# [highlighting](http://www.elasticsearch.org/guide/reference/api/search/highlighting.html)
# features, and _Tire_ makes them trivial to use.
#
s = Tire.search 'articles' do

  # Let's search for documents containing word “Two” in their titles,
  query { string 'title:Two' }

   # and instruct _Elasticsearch_ to highlight relevant snippets.
   #
  highlight :title
end

# The results:
#     Title: Two; Highlighted: <em>Two</em>
#
s.results.each do |document|
  puts "Title: #{ document.title }; Highlighted: #{document.highlight.title}"
end

# We can configure many options for highlighting, such as:
#
s = Tire.search 'articles' do
  query { string 'title:Two' }

  # • specify the fields to highlight
  #
  highlight :title, :body

  # • specify their individual options
  #
  highlight :title, :body => { :number_of_fragments => 0 }

  # • or specify global highlighting options, such as the wrapper tag
  #
  highlight :title, :body, :options => { :tag => '<strong class="highlight">' }
end

#### Suggest

#
# _Elasticsearch_
# [suggest](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/search-suggesters.html)
# feature suggests similar terms based on user input.
# You can specify either the `term` or `phrase` suggester in the Tire DSL, or
# use the `completion` suggester to get fast completions of user inputs, suitable
# for auto-complete and instant search features.

# Suggestion API is available either as standalone method or part of the search request.

# To get search suggestions while doing a search, call the suggest API
#
s = Tire.search 'articles' do

  # To define a suggest using the term suggester, first provide a custom name for the suggest.
  #
  suggest :suggest_title do
    # Specify the input text.
    #
    text 'thrree blind mice'
    # Then, define the field you want to use for suggestions and any options.
    #
    term :title, size: 3, sort: 'frequency'
  end

  # To define a suggest using the `phrase` suggest, use a different name.
  suggest :phrase_suggest_title do
    # Specify the text input text.
    #
    text 'thrree blind mice'
    # Again, define the field you want to use for suggestions and any options.
    #
    phrase :title, size: 3 do
      # Optinally, configure the `smoothing` option...
      #
      smoothing :stupid_backoff, discount: 0.5

      # ...or the `generator` option.
      generator :title, min_word_len: 1
    end
  end
end

# The results will be available in the `suggestions` property (which is iterable)
#
s.results.suggestions.each do |name, options|
  puts "Suggestion returned for #{name}:\n"
  options.each do |option|
    puts "* Raw result: #{option}"
  end
end

# You can also use helper methods available in suggestions results to get only
# the suggested terms or phrases.
#
puts "Available corrections for suggest_title: #{s.results.suggestions.texts(:suggest_title).join(', ')}"

# You can use the standalone API to achieve the same result:
#
s = Tire.suggest('articles') do

  # Notice that for standalone API, the block method is `suggestion` rather than `suggest`:
  #
  suggestion :term_suggest do
    text 'thrree'
    term :title, size: 3, sort: 'frequency'
  end

end

# You'll get the same object as above but as top level object
#
puts "Available corrections: #{s.results.texts.join(', ')}"

#### Completion

# In order to use _Elasticsearch_ completion you'll need to update your mappings to provide a field
# with completion type. The example is adapted from this
# [blog post](http://www.elasticsearch.org/blog/you-complete-me/).
#
index = Tire.index('hotels') do
  delete

  # Notice the type completion for the field _name_suggest_:
  #
  create :mappings => {
      :hotel => {
          :properties => {
              :name => {:type => 'string'},
              :city => {:type => 'string'},
              :name_suggest => {:type => 'completion'}
          }
      }
  }

  # Let's add some documents into this index:
  #
  import([
             {:id => '1', :type => 'hotel', :name => 'Mercure Hotel Munich', :city => 'Munich', :name_suggest => 'Mercure Hotel Munich'},
             {:id => '2', :type => 'hotel', :name => 'Hotel Monaco', :city => 'Munich', :name_suggest => 'Hotel Monaco'},
         ])
  refresh

end

# We can ask for all hotels starting with a given prefix (such as "m") with this query:
#
s = Tire.suggest('hotels') do
  suggestion 'complete' do
    text 'm'
    completion 'name_suggest'
  end
end

# And retrieve results as above with the same object:
#
puts "There are #{s.results.texts.size} hotels starting with m:"
s.results.texts.each do |hotel|
  puts "* #{hotel}"
end

# You can use some advanced features of completion such as multiple inputs and unified output for
# the same document.

# If you add a document which has inputs and output values for the suggest field:
#
index.store({:id => '1', :type => 'hotel', :name => 'Mercure Hotel Munich', :city => 'Munich',
             :name_suggest => {:input => ['Mercure Hotel Munich', 'Mercure Munich'], :output => 'Hotel Mercure'}})
index.store({:id => '2', :type => 'hotel', :name => 'Hotel Monaco', :city => 'Munich',
             :name_suggest => {:input => ['Monaco Munich', 'Hotel Monaco'], :output => 'Hotel Monaco'}})
index.refresh

# ... a completion request with the same input as above ...
#
s = Tire.suggest('hotels') do
  suggestion 'complete' do
    text 'm'
    completion 'name_suggest'
  end
end

# ... will match multiple inputs for the same document and return unified output in results:
#
puts "There are #{s.results.texts.size} hotels starting with m:"
s.results.texts.each do |hotel|
  puts "* #{hotel}"
end

#### Percolation

# _Elasticsearch_ comes with one very interesting, and rather unique feature:
# [_percolation_](http://www.elasticsearch.org/guide/reference/api/percolate.html).

# It works in a „reverse search“ manner to regular search workflow of adding
# documents to the index and then querying them.
# Percolation allows us to register a query, and ask if a specific document
# matches it, either on demand, or immediately as the document is being indexed.

# Let's review an example for an index named _weather_.
# We will register three queries for percolation against this index.
#
index = Tire.index('weather') do
  delete
  create

  # First, a query named _warning_,
  #
  register_percolator_query('warning', :tags => ['warning']) { string 'warning OR severe OR extreme' }

  # a query named _tsunami_,
  #
  register_percolator_query('tsunami', :tags => ['tsunami']) { string 'tsunami' }

  # and a query named _floods_.
  #
  register_percolator_query('floods',  :tags => ['floods'])  { string 'flood*' }

end

# Notice, that we have added a _tags_ field to the query document, because it behaves
# just like any other document in _Elasticsearch_.

# We will refresh the `_percolator` index for immediate access.
#
Tire.index('_percolator').refresh

# Now, let's _percolate_ a document containing some trigger words against all registered queries.
#
matches = index.percolate(:message => '[Warning] Extreme flooding expected after tsunami wave.')

# The result will contain, unsurprisingly, names of all the three registered queries:
#
#     Matching queries: ["floods", "tsunami", "warning"]
#
puts "Matching queries: " + matches.inspect

# We can filter the executed queries with a regular _Elasticsearch_ query passed as a block to
# the `percolate` method.
#
matches = index.percolate(:message => '[Warning] Extreme flooding expected after tsunami wave.') do
            # Let's use a _terms_ query against the `tags` field.
            term :tags, 'tsunami'
          end

# In this case, the result will contain only the name of the “tsunami” query.
#
#     Matching queries: ["tsunami"]
#
puts "Matching queries: " + matches.inspect

# What if we percolate another document, without the “tsunami” trigger word?
#
matches = index.percolate(:message => '[Warning] Extreme temperatures expected.') { term :tags, 'tsunami' }

# As expected, we will get an empty array:
#
#     Matching queries: []
#
puts "Matching queries: " + matches.inspect

# Well, that's of course immensely useful for real-time search systems. But, there's more.
# We can _percolate_ a document _at the same time_ it is being stored in the index,
# getting back a list of matching queries.

# Let's store a document with some trigger words in the index, and mark it for percolation.
#
response = index.store( { :message => '[Warning] Severe floods expected after tsunami wave.' },
                        { :percolate => true } )

# We will get the names of all matching queries in response.
#
#     Matching queries: ["floods", "tsunami", "warning"]
#
puts "Matching queries: " + response['matches'].inspect

# As with the _percolate_ example, we can filter the executed queries.
#
response = index.store( { :message => '[Warning] Severe floods expected after tsunami wave.' },
                         # Let's use a simple string query for the “tsunami” tag.
                        { :percolate => 'tags:tsunami' } )

# Unsurprisingly, the response will contain just the name of the “tsunami” query.
#
#     Matching queries: ["tsunami"]
#
puts "Matching queries: " + response['matches'].inspect

### ActiveModel Integration

# As you can see, [_Tire_](https://github.com/karmi/tire) supports the
# main features of _Elasticsearch_ in Ruby.
#
# It allows you to create and delete indices, add documents, search them, retrieve the facets, highlight the results,
# and comes with a usable logging facility.
#
# Of course, the holy grail of any search library is easy, painless integration with your Ruby classes, and,
# most importantly, with ActiveRecord/ActiveModel classes.
#
# Please, check out the [README](https://github.com/karmi/tire/tree/master#readme) file for instructions
# how to include _Tire_-based search in your models..
#
# Send any feedback via Github issues, or ask questions in the [#elasticsearch](irc://irc.freenode.net/#elasticsearch) IRC channel.
