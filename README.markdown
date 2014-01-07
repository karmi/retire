Tire
=========

---------------------------------------------------------------------------------------------------

  NOTICE: This library has been renamed and retired in September 2013
          ([read the explanation](https://github.com/karmi/retire/wiki/Tire-Retire)).

  Have a look at the **<http://github.com/elasticsearch/elasticsearch-ruby>**
  suite of gems, which will contain similar set of features for
  ActiveRecord and Rails integration as Tire.

---------------------------------------------------------------------------------------------------

_Tire_ is a Ruby (1.8 or 1.9) client for the [Elasticsearch](http://www.elasticsearch.org/)
search engine/database.

_Elasticsearch_ is a scalable, distributed, cloud-ready, highly-available,
full-text search engine and database with
[powerful aggregation features](http://www.elasticsearch.org/guide/reference/api/search/facets/),
communicating by JSON over RESTful HTTP, based on [Lucene](http://lucene.apache.org/), written in Java.

This Readme provides a brief overview of _Tire's_ features. The more detailed documentation is at <http://karmi.github.com/retire/>.

Both of these documents contain a lot of information. Please set aside some time to read them thoroughly, before you blindly dive into „somehow making it work“. Just skimming through it **won't work** for you. For more information, please see the project [Wiki](https://github.com/karmi/tire/wiki/_pages), search the [issues](https://github.com/karmi/tire/issues), and refer to the [integration test suite](https://github.com/karmi/tire/tree/master/test/integration).

Installation
------------

OK. First, you need a running _Elasticsearch_ server. Thankfully, it's easy. Let's define easy:

    $ curl -k -L -o elasticsearch-0.20.6.tar.gz http://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.20.6.tar.gz
    $ tar -zxvf elasticsearch-0.20.6.tar.gz
    $ ./elasticsearch-0.20.6/bin/elasticsearch -f

See, easy. On a Mac, you can also use _Homebrew_:

    $ brew install elasticsearch

Now, let's install the gem via Rubygems:

    $ gem install tire

Of course, you can install it from the source as well:

    $ git clone git://github.com/karmi/tire.git
    $ cd tire
    $ rake install


Usage
-----

_Tire_ exposes easy-to-use domain specific language for fluent communication with _Elasticsearch_.

It easily blends with your _ActiveModel_/_ActiveRecord_ classes for convenient usage in _Rails_ applications.

To test-drive the core _Elasticsearch_ functionality, let's require the gem:

```ruby
    require 'rubygems'
    require 'tire'
```

Please note that you can copy these snippets from the much more extensive and heavily annotated file
in [examples/tire-dsl.rb](http://karmi.github.com/retire/).

Also, note that we're doing some heavy JSON lifting here. _Tire_ uses the
[_multi_json_](https://github.com/intridea/multi_json) gem as a generic JSON wrapper,
which allows you to use your preferred JSON library. We'll use the
[_yajl-ruby_](https://github.com/brianmario/yajl-ruby) gem in the full on mode here:

```ruby
    require 'yajl/json_gem'
```

Let's create an index named `articles` and store/index some documents:

```ruby
    Tire.index 'articles' do
      delete
      create

      store :title => 'One',   :tags => ['ruby']
      store :title => 'Two',   :tags => ['ruby', 'python']
      store :title => 'Three', :tags => ['java']
      store :title => 'Four',  :tags => ['ruby', 'php']

      refresh
    end
```

We can also create the index with custom
[mapping](http://www.elasticsearch.org/guide/reference/api/admin-indices-create-index.html)
for a specific document type:

```ruby
    Tire.index 'articles' do
      delete

      create :mappings => {
        :article => {
          :properties => {
            :id       => { :type => 'string', :index => 'not_analyzed', :include_in_all => false },
            :title    => { :type => 'string', :boost => 2.0,            :analyzer => 'snowball'  },
            :tags     => { :type => 'string', :analyzer => 'keyword'                             },
            :content  => { :type => 'string', :analyzer => 'snowball'                            }
          }
        }
      }
    end
```

Of course, we may have large amounts of data, and it may be impossible or impractical to add them to the index
one by one. We can use _Elasticsearch's_
[bulk storage](http://www.elasticsearch.org/guide/reference/api/bulk.html).
Notice, that collection items must have an `id` property or method,
and should have a `type` property, if you've set any specific mapping for the index.

```ruby
    articles = [
      { :id => '1', :type => 'article', :title => 'one',   :tags => ['ruby']           },
      { :id => '2', :type => 'article', :title => 'two',   :tags => ['ruby', 'python'] },
      { :id => '3', :type => 'article', :title => 'three', :tags => ['java']           },
      { :id => '4', :type => 'article', :title => 'four',  :tags => ['ruby', 'php']    }
    ]

    Tire.index 'articles' do
      import articles
    end
```

We can easily manipulate the documents before storing them in the index, by passing a block to the
`import` method, like this:

```ruby
    Tire.index 'articles' do
      import articles do |documents|

        documents.each { |document| document[:title].capitalize! }
      end

      refresh
    end
```

If this _declarative_ notation does not fit well in your context,
you can use _Tire's_ classes directly, in a more imperative manner:

```ruby
    index = Tire::Index.new('oldskool')
    index.delete
    index.create
    index.store :title => "Let's do it the old way!"
    index.refresh
```

OK. Now, let's go search all the data.

We will be searching for articles whose `title` begins with letter “T”, sorted by `title` in `descending` order,
filtering them for ones tagged “ruby”, and also retrieving some [_facets_](http://www.elasticsearch.org/guide/reference/api/search/facets/)
from the database:

```ruby
    s = Tire.search 'articles' do
      query do
        string 'title:T*'
      end

      filter :terms, :tags => ['ruby']

      sort { by :title, 'desc' }

      facet 'global-tags', :global => true do
        terms :tags
      end

      facet 'current-tags' do
        terms :tags
      end
    end
```

(Of course, we may also page the results with `from` and `size` query options, retrieve only specific fields
or highlight content matching our query, etc.)

Let's display the results:

```ruby
    s.results.each do |document|
      puts "* #{ document.title } [tags: #{document.tags.join(', ')}]"
    end

    # * Two [tags: ruby, python]
```

Let's display the global facets (distribution of tags across the whole database):

```ruby
    s.results.facets['global-tags']['terms'].each do |f|
      puts "#{f['term'].ljust(10)} #{f['count']}"
    end

    # ruby       3
    # python     1
    # php        1
    # java       1
```

Now, let's display the facets based on current query (notice that count for articles
tagged with 'java' is included, even though it's not returned by our query;
count for articles tagged 'php' is excluded, since they don't match the current query):

```ruby
    s.results.facets['current-tags']['terms'].each do |f|
      puts "#{f['term'].ljust(10)} #{f['count']}"
    end

    # ruby       1
    # python     1
    # java       1
```

Notice, that only variables from the enclosing scope are accessible.
If we want to access the variables or methods from outer scope,
we have to use a slight variation of the DSL, by passing the
`search` and `query` objects around.

```ruby
    @query = 'title:T*'

    Tire.search 'articles' do |search|
      search.query do |query|
        query.string @query
      end
    end
```

Quite often, we need complex queries with boolean logic.
Instead of composing long query strings such as `tags:ruby OR tags:java AND NOT tags:python`,
we can use the [_bool_](http://www.elasticsearch.org/guide/reference/query-dsl/bool-query.html)
query. In _Tire_, we build them declaratively.

```ruby
    Tire.search 'articles' do
      query do
        boolean do
          should   { string 'tags:ruby' }
          should   { string 'tags:java' }
          must_not { string 'tags:python' }
        end
      end
    end
```

The best thing about `boolean` queries is that we can easily save these partial queries as Ruby blocks,
to mix and reuse them later. So, we may define a query for the _tags_ property:

```ruby
    tags_query = lambda do |boolean|
      boolean.should { string 'tags:ruby' }
      boolean.should { string 'tags:java' }
    end
```

And a query for the _published_on_ property:

```ruby
    published_on_query = lambda do |boolean|
      boolean.must   { string 'published_on:[2011-01-01 TO 2011-01-02]' }
    end
```

Now, we can combine these queries for different searches:

```ruby
    Tire.search 'articles' do
      query do
        boolean &tags_query
        boolean &published_on_query
      end
    end
```

Note, that you can pass options for configuring queries, facets, etc. by passing a Hash as the last argument to the method call:

```ruby
    Tire.search 'articles' do
      query do
        string 'ruby python', :default_operator => 'AND', :use_dis_max => true
      end
    end
```

You don't have to define the search criteria in one monolithic _Ruby_ block -- you can build the search step by step,
until you call the `results` method:

```ruby
    s = Tire.search('articles') { query { string 'title:T*' } }
    s.filter :terms, :tags => ['ruby']
    p s.results
```

If configuring the search payload with blocks feels somehow too weak for you, you can pass
a plain old Ruby `Hash` (or JSON string) with the query declaration to the `search` method:

```ruby
    Tire.search 'articles', :query => { :prefix => { :title => 'fou' } }
```

If this sounds like a great idea to you, you are probably able to write your application
using just `curl`, `sed` and `awk`.

Do note again, however, that you're not tied to the declarative block-style DSL _Tire_ offers to you.
If it makes more sense in your context, you can use the API directly, in a more imperative style:

```ruby
    search = Tire::Search::Search.new('articles')
    search.query  { string('title:T*') }
    search.filter :terms, :tags => ['ruby']
    search.sort   { by :title, 'desc' }
    search.facet('global-tags') { terms :tags, :global => true }
    # ...
    p search.results
```

To debug the query we have laboriously set up like this,
we can display the full query JSON for close inspection:

```ruby
    puts s.to_json
    # {"facets":{"current-tags":{"terms":{"field":"tags"}},"global-tags":{"global":true,"terms":{"field":"tags"}}},"query":{"query_string":{"query":"title:T*"}},"filter":{"terms":{"tags":["ruby"]}},"sort":[{"title":"desc"}]}
```

Or, better, we can display the corresponding `curl` command to recreate and debug the request in the terminal:

```ruby
    puts s.to_curl
    # curl -X POST "http://localhost:9200/articles/_search?pretty=true" -d '{"facets":{"current-tags":{"terms":{"field":"tags"}},"global-tags":{"global":true,"terms":{"field":"tags"}}},"query":{"query_string":{"query":"title:T*"}},"filter":{"terms":{"tags":["ruby"]}},"sort":[{"title":"desc"}]}'
```

However, we can simply log every search query (and other requests) in this `curl`-friendly format:

```ruby
    Tire.configure { logger 'elasticsearch.log' }
```

When you set the log level to _debug_:

```ruby
    Tire.configure { logger 'elasticsearch.log', :level => 'debug' }
```

the JSON responses are logged as well. This is not a great idea for production environment,
but it's priceless when you want to paste a complicated transaction to the mailing list or IRC channel.

The _Tire_ DSL tries hard to provide a strong Ruby-like API for the main _Elasticsearch_ features.

By default, _Tire_ wraps the results collection in a enumerable `Results::Collection` class,
and result items in a `Results::Item` class, which looks like a child of `Hash` and `Openstruct`,
for smooth iterating over and displaying the results.

You may wrap the result items in your own class by setting the `Tire.configuration.wrapper`
property. Your class must take a `Hash` of attributes on initialization.

If that seems like a great idea to you, there's a big chance you already have such class.

One would bet it's an `ActiveRecord` or `ActiveModel` class, containing model of your Rails application.

Fortunately, _Tire_ makes blending _Elasticsearch_ features into your models trivially possible.


ActiveModel Integration
-----------------------

If you're the type with no time for lengthy introductions, you can generate a fully working
example Rails application, with an `ActiveRecord` model and a search form, to play with
(it even downloads _Elasticsearch_ itself, generates the application skeleton and leaves you with
a _Git_ repository to explore the steps and the code):

    $ rails new searchapp -m https://raw.github.com/karmi/tire/master/examples/rails-application-template.rb

For the rest of us, let's suppose you have an `Article` class in your _Rails_ application.

To make it searchable with _Tire_, just `include` it:

```ruby
    class Article < ActiveRecord::Base
      include Tire::Model::Search
      include Tire::Model::Callbacks
    end
```

When you now save a record:

```ruby
    Article.create :title =>   "I Love Elasticsearch",
                   :content => "...",
                   :author =>  "Captain Nemo",
                   :published_on => Time.now
```

it is automatically added into an index called 'articles', because of the included callbacks.

The document attributes are indexed exactly as when you call the `Article#to_json` method.

Now you can search the records:

```ruby
    Article.search 'love'
```

OK. This is where the search game stops, often. Not here.

First of all, you may use the full query DSL, as explained above, with filters, sorting,
advanced facet aggregation, highlighting, etc:

```ruby
    Article.search do
      query             { string 'love' }
      facet('timeline') { date   :published_on, :interval => 'month' }
      sort              { by     :published_on, 'desc' }
    end
```

Second, dynamic mapping is a godsend when you're prototyping.
For serious usage, though, you'll definitely want to define a custom _mapping_ for your models:

```ruby
    class Article < ActiveRecord::Base
      include Tire::Model::Search
      include Tire::Model::Callbacks

      mapping do
        indexes :id,           :index    => :not_analyzed
        indexes :title,        :analyzer => 'snowball', :boost => 100
        indexes :content,      :analyzer => 'snowball'
        indexes :content_size, :as       => 'content.size'
        indexes :author,       :analyzer => 'keyword'
        indexes :published_on, :type => 'date', :include_in_all => false
      end
    end
```

In this case, _only_ the defined model attributes are indexed. The `mapping` declaration creates the
index when the class is loaded or when the importing features are used, and _only_ when it does not yet exist.

You can define different [_analyzers_](http://www.elasticsearch.org/guide/reference/index-modules/analysis/index.html),
[_boost_](http://www.elasticsearch.org/guide/reference/mapping/boost-field.html) levels for different properties,
or any other configuration for _elasticsearch_.

You're not limited to 1:1 mapping between your model properties and the serialized document. With the `:as` option,
you can pass a string or a _Proc_ object which is evaluated in the instance context (see the `content_size` property).

Chances are, you want to declare also a custom _settings_ for the index, such as set the number of shards,
replicas, or create elaborate analyzer chains, such as the hipster's choice: [_ngrams_](https://gist.github.com/1160430).
In this case, just wrap the `mapping` method in a `settings` one, passing it the settings as a Hash:

```ruby
    class URL < ActiveRecord::Base
      include Tire::Model::Search
      include Tire::Model::Callbacks

      settings :number_of_shards => 1,
               :number_of_replicas => 1,
               :analysis => {
                 :filter => {
                   :url_ngram  => {
                     "type"     => "nGram",
                     "max_gram" => 5,
                     "min_gram" => 3 }
                 },
                 :analyzer => {
                   :url_analyzer => {
                      "tokenizer"    => "lowercase",
                      "filter"       => ["stop", "url_ngram"],
                      "type"         => "custom" }
                 }
               } do
        mapping { indexes :url, :type => 'string', :analyzer => "url_analyzer" }
      end
    end
```

Note, that the index will be created with settings and mappings only when it doesn't exist yet.
To re-create the index with correct configuration, delete it first: `URL.index.delete` and
create it afterwards: `URL.create_elasticsearch_index`.

It may well be reasonable to wrap the index creation logic declared with `Tire.index('urls').create`
in a class method of your model, in a module method, etc, to have better control on index creation when
bootstrapping the application with Rake tasks or when setting up the test suite.
_Tire_ will not hold that against you.

You may have just stopped wondering: what if I have my own `settings` class method defined?
Or what if some other gem defines `settings`, or some other _Tire_ method, such as `update_index`?
Things will break, right? No, they won't.

In fact, all this time you've been using only _proxies_ to the real _Tire_ methods, which live in the `tire`
class and instance methods of your model. Only when not trampling on someone's foot — which is the majority
of cases —, will _Tire_ bring its methods to the namespace of your class.

So, instead of writing `Article.search`, you could write `Article.tire.search`, and instead of
`@article.update_index` you could write `@article.tire.update_index`, to be on the safe side.
Let's have a look on an example with the `mapping` method:

```ruby
    class Article < ActiveRecord::Base
      include Tire::Model::Search
      include Tire::Model::Callbacks

      tire.mapping do
        indexes :id, :type => 'string', :index => :not_analyzed
        # ...
      end
    end
```

Of course, you could also use the block form:

```ruby
    class Article < ActiveRecord::Base
      include Tire::Model::Search
      include Tire::Model::Callbacks

      tire do
        mapping do
          indexes :id, :type => 'string', :index => :not_analyzed
          # ...
        end
      end
    end
```

Internally, _Tire_ uses these proxy methods exclusively. When you run into issues,
use the proxied method, eg. `Article.tire.mapping`, directly.

When you want a tight grip on how the attributes are added to the index, just
implement the `to_indexed_json` method in your model.

The easiest way is to customize the `to_json` serialization support of your model:

```ruby
    class Article < ActiveRecord::Base
      # ...

      self.include_root_in_json = false
      def to_indexed_json
        to_json :except => ['updated_at'], :methods => ['length']
      end
    end
```

Of course, it may well be reasonable to define the indexed JSON from the ground up:

```ruby
    class Article < ActiveRecord::Base
      # ...

      def to_indexed_json
        names      = author.split(/\W/)
        last_name  = names.pop
        first_name = names.join

        {
          :title   => title,
          :content => content,
          :author  => {
            :first_name => first_name,
            :last_name  => last_name
          }
        }.to_json
      end
    end
```

Notice, that you may want to skip including the `Tire::Model::Callbacks` module in special cases,
like when your records are indexed via some external mechanism, let's say a _CouchDB_ or _RabbitMQ_
[river](http://www.elasticsearch.org/blog/2010/09/28/the_river.html), or when you need better
control on how the documents are added to or removed from the index:

```ruby
    class Article < ActiveRecord::Base
      include Tire::Model::Search

      after_save do
        update_index if state == 'published'
      end
    end
```

Sometimes, you might want to have complete control about the indexing process. In such situations,
just drop down one layer and use the `Tire::Index#store` and `Tire::Index#remove` methods directly:

```ruby
    class Article < ActiveRecord::Base
      acts_as_paranoid
      include Tire::Model::Search

      after_save do
        if deleted_at.nil?
          self.index.store self
        else
          self.index.remove self
        end
      end
    end
```

Of course, in this way, you're still performing an HTTP request during your database transaction,
which is not optimal for large-scale applications. In these situations, a better option would be processing
the index operations in background, with something like [Resque](https://github.com/resque/resque) or
[Sidekiq](https://github.com/mperham/sidekiq):

```ruby
    class Article < ActiveRecord::Base
      include Tire::Model::Search

      after_save    { Indexer::Index.perform_async(document) }
      after_destroy { Indexer::Remove.perform_async(document) }
    end
```

When you're integrating _Tire_ with ActiveRecord models, you should use the `after_commit`
and `after_rollback` hooks to keep the index in sync with your database.

The results returned by `Article.search` are wrapped in the aforementioned `Item` class, by default.
This way, we have a fast and flexible access to the properties returned from _Elasticsearch_ (via the
`_source` or `fields` JSON properties). This way, we can index whatever JSON we like in _Elasticsearch_,
and retrieve it, simply, via the dot notation:

```ruby
    articles = Article.search 'love'
    articles.each do |article|
      puts article.title
      puts article.author.last_name
    end
```

The `Item` instances masquerade themselves as instances of your model within a _Rails_ application
(based on the `_type` property retrieved from _Elasticsearch_), so you can use them carefree;
all the `url_for` or `dom_id` helpers work as expected.

If you need to access the “real” model (eg. to access its associations or methods not
stored in _Elasticsearch_), just load it from the database:

```ruby
    puts article.load(:include => 'comments').comments.size
```

You can see that _Tire_ stays as far from the database as possible. That's because it believes
you have most of the data you want to display stored in _Elasticsearch_. When you need
to eagerly load the records from the database itself, for whatever reason,
you can do it with the `:load` option when searching:

```ruby
    # Will call `Article.search [1, 2, 3]`
    Article.search 'love', :load => true
```

Instead of simple `true`, you can pass any options for the model's find method:

```ruby
    # Will call `Article.search [1, 2, 3], :include => 'comments'`
    Article.search :load => { :include => 'comments' } do
      query { string 'love' }
    end
```

If you would like to access properties returned by Elasticsearch (such as `_score`),
in addition to model instance, use the `each_with_hit` method:

```ruby
    results = Article.search 'One', :load => true
    results.each_with_hit do |result, hit|
      puts "#{result.title} (score: #{hit['_score']})"
    end

    # One (score: 0.300123)
```

Note that _Tire_ search results are fully compatible with [_WillPaginate_](https://github.com/mislav/will_paginate)
and [_Kaminari_](https://github.com/amatsuda/kaminari), so you can pass all the usual parameters to the
`search` method in the controller:

```ruby
    @articles = Article.search params[:q], :page => (params[:page] || 1)
```

OK. Chances are, you have lots of records stored in your database. How will you get them to _Elasticsearch_? Easy:

```ruby
    Article.index.import Article.all
```

This way, however, all your records are loaded into memory, serialized into JSON,
and sent down the wire to _Elasticsearch_. Not practical, you say? You're right.

When your model is an `ActiveRecord::Base` or `Mongoid::Document` one, or when it implements
some sort of pagination, you can just run:

```ruby
    Article.import
```

Depending on the setup of your model, either `find_in_batches`, `limit..skip` or pagination is used
to import your data.

Are we saying you have to fiddle with this thing in a `rails console` or silly Ruby scripts? No.
Just call the included _Rake_ task on the command line:

```bash
    $ rake environment tire:import:all
```

You can also force-import the data by deleting the index first (and creating it with
correct settings and/or mappings provided by the `mapping` block in your model):

```bash
    $ rake environment tire:import CLASS='Article' FORCE=true
```

When you'll spend more time with _Elasticsearch_, you'll notice how
[index aliases](http://www.elasticsearch.org/guide/reference/api/admin-indices-aliases.html)
are the best idea since the invention of inverted index.
You can index your data into a fresh index (and possibly update an alias once everything's fine):

```bash
    $ rake environment tire:import CLASS='Article' INDEX='articles-2011-05'
```

Finally, consider the Rake importing task just a convenient starting point. If you're loading
substantial amounts of data, want better control on which data will be indexed, etc., use the
lower-level Tire API with eg. `ActiveRecordBase#find_in_batches` directly:

```ruby
    Article.where("published_on > ?", Time.parse("2012-10-01")).find_in_batches(include: authors) do |batch|
      Tire.index("articles").import batch
    end
```
If you're using a different database, such as [MongoDB](http://www.mongodb.org/),
another object mapping library, such as [Mongoid](http://mongoid.org/) or [MongoMapper](http://mongomapper.com/),
things stay mostly the same:

```ruby
    class Article
      include Mongoid::Document
      field :title, :type => String
      field :content, :type => String

      include Tire::Model::Search
      include Tire::Model::Callbacks

      # These Mongo guys sure do get funky with their IDs in +serializable_hash+, let's fix it.
      #
      def to_indexed_json
        self.to_json
      end

    end

    Article.create :title => 'I Love Elasticsearch'

    Article.tire.search 'love'
```

_Tire_ does not care what's your primary data storage solution, if it has an _ActiveModel_-compatible
adapter. But there's more.

_Tire_ implements not only _searchable_ features, but also _persistence_ features. This means you can use a _Tire_ model **instead of your database**, not just for _searching_ your database. Why would you like to do that?

Well, because you're tired of database migrations and lots of hand-holding with your
database to store stuff like `{ :name => 'Tire', :tags => [ 'ruby', 'search' ] }`.
Because all you need, really, is to just dump a JSON-representation of your data into a database and load it back again.
Because you've noticed that _searching_ your data is a much more effective way of retrieval
then constructing elaborate database query conditions.
Because you have _lots_ of data and want to use _Elasticsearch's_ advanced distributed features.

All good reasons to use _Elasticsearch_ as a schema-free and highly-scalable storage and retrieval/aggregation engine for your data.

To use the persistence mode, we'll include the `Tire::Persistence` module in our class and define its properties;
we can add the standard mapping declarations, set default values, or define casting for the property to create
lightweight associations between the models.

```ruby
    class Article
      include Tire::Model::Persistence

      validates_presence_of :title, :author

      property :title,        :analyzer => 'snowball'
      property :published_on, :type => 'date'
      property :tags,         :default => [], :analyzer => 'keyword'
      property :author,       :class => Author
      property :comments,     :class => [Comment]
    end
```

Please be sure to peruse the [integration test suite](https://github.com/karmi/tire/tree/master/test/integration)
for examples of the API and _ActiveModel_ integration usage.


Extensions and Additions
------------------------

The [_tire-contrib_](http://github.com/karmi/tire-contrib/) project contains additions
and extensions to the core _Tire_ functionality — be sure to check them out.


Other Clients
-------------

Check out [other _Elasticsearch_ clients](http://www.elasticsearch.org/guide/clients/).


Feedback
--------

You can send feedback via [e-mail](mailto:karmi@karmi.cz) or via [Github Issues](https://github.com/karmi/tire/issues).

-----

[Karel Minarik](http://karmi.cz) and [contributors](http://github.com/karmi/tire/contributors)

![](https://ga-beacon.appspot.com/UA-46901128-1/karmi/retire?pixel)
