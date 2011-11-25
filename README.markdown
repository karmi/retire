Tire
=========

_Tire_ is a Ruby (1.8 or 1.9) client for the [ElasticSearch](http://www.elasticsearch.org/)
search engine/database.

_ElasticSearch_ is a scalable, distributed, cloud-ready, highly-available,
full-text search engine and database with
[powerfull aggregation features](http://www.elasticsearch.org/guide/reference/api/search/facets/),
communicating by JSON over RESTful HTTP, based on [Lucene](http://lucene.apache.org/), written in Java.

This Readme provides a brief overview of _Tire's_ features. The more detailed documentation is at <http://karmi.github.com/tire/>.

Both of these documents contain a lot of information. Please set aside some time to read them thoroughly, before you blindly dive into „somehow making it work“. Just skimming through it **won't work** for you. For more information, please refer to the [integration test suite](https://github.com/karmi/tire/tree/master/test/integration)
and [issues](https://github.com/karmi/tire/issues).

Installation
------------

OK. First, you need a running _ElasticSearch_ server. Thankfully, it's easy. Let's define easy:

    $ curl -k -L -o elasticsearch-0.17.6.tar.gz http://github.com/downloads/elasticsearch/elasticsearch/elasticsearch-0.17.6.tar.gz
    $ tar -zxvf elasticsearch-0.17.6.tar.gz
    $ ./elasticsearch-0.17.6/bin/elasticsearch -f

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

_Tire_ exposes easy-to-use domain specific language for fluent communication with _ElasticSearch_.

It easily blends with your _ActiveModel_/_ActiveRecord_ classes for convenient usage in _Rails_ applications.

To test-drive the core _ElasticSearch_ functionality, let's require the gem:

```ruby
    require 'rubygems'
    require 'tire'
```

Please note that you can copy these snippets from the much more extensive and heavily annotated file
in [examples/tire-dsl.rb](http://karmi.github.com/tire/).

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
one by one. We can use _ElasticSearch's_
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

      facet 'global-tags' do
        terms :tags, :global => true
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
    tags_query = lambda do
      boolean.should { string 'tags:ruby' }
      boolean.should { string 'tags:java' }
    end
```

And a query for the _published_on_ property:

```ruby
    published_on_query = lambda do
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

If configuring the search payload with blocks feels somehow too weak for you, you can pass
a plain old Ruby `Hash` (or JSON string) with the query declaration to the `search` method:

```ruby
    Tire.search 'articles', :query => { :fuzzy => { :title => 'Sour' } }
```

If this sounds like a great idea to you, you are probably able to write your application
using just `curl`, `sed` and `awk`.

Do note again, however, that you're not tied to the declarative block-style DSL _Tire_ offers to you.
If it makes more sense in your context, you can use its classes directly, in a more imperative style:

```ruby
    search = Tire::Search::Search.new('articles')
    search.query  { string('title:T*') }
    search.filter :terms, :tags => ['ruby']
    search.sort   { by :title, 'desc' }
    search.facet('global-tags') { terms :tags, :global => true }
    # ...
    p search.perform.results
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

The _Tire_ DSL tries hard to provide a strong Ruby-like API for the main _ElasticSearch_ features.

By default, _Tire_ wraps the results collection in a enumerable `Results::Collection` class,
and result items in a `Results::Item` class, which looks like a child of `Hash` and `Openstruct`,
for smooth iterating over and displaying the results.

You may wrap the result items in your own class by setting the `Tire.configuration.wrapper`
property. Your class must take a `Hash` of attributes on initialization.

If that seems like a great idea to you, there's a big chance you already have such class.

One would bet it's an `ActiveRecord` or `ActiveModel` class, containing model of your Rails application.

Fortunately, _Tire_ makes blending _ElasticSearch_ features into your models trivially possible.


ActiveModel Integration
-----------------------

If you're the type with no time for lengthy introductions, you can generate a fully working
example Rails application, with an `ActiveRecord` model and a search form, to play with
(it even downloads _ElasticSearch_ itself, generates the application skeleton and leaves you with
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
    Article.create :title =>   "I Love ElasticSearch",
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
        indexes :id,           :type => 'string',  :index    => :not_analyzed
        indexes :title,        :type => 'string',  :analyzer => 'snowball', :boost => 100
        indexes :content,      :type => 'string',  :analyzer => 'snowball'
        indexes :author,       :type => 'string',  :analyzer => 'keyword'
        indexes :published_on, :type => 'date',    :include_in_all => false
      end
    end
```

In this case, _only_ the defined model attributes are indexed. The `mapping` declaration creates the
index when the class is loaded or when the importing features are used, and _only_ when it does not yet exist.

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

      include_root_in_json = false
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

The results returned by `Article.search` are wrapped in the aforementioned `Item` class, by default.
This way, we have a fast and flexible access to the properties returned from _ElasticSearch_ (via the
`_source` or `fields` JSON properties). This way, we can index whatever JSON we like in _ElasticSearch_,
and retrieve it, simply, via the dot notation:

```ruby
    articles = Article.search 'love'
    articles.each do |article|
      puts article.title
      puts article.author.last_name
    end
```

The `Item` instances masquerade themselves as instances of your model within a _Rails_ application
(based on the `_type` property retrieved from _ElasticSearch_), so you can use them carefree;
all the `url_for` or `dom_id` helpers work as expected.

If you need to access the “real” model (eg. to access its assocations or methods not
stored in _ElasticSearch_), just load it from the database:

```ruby
    puts article.load(:include => 'comments').comments.size
```

You can see that _Tire_ stays as far from the database as possible. That's because it believes
you have most of the data you want to display stored in _ElasticSearch_. When you need
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

Note that _Tire_ search results are fully compatible with [`will_paginate`](https://github.com/mislav/will_paginate),
so you can pass all the usual parameters to the `search` method in the controller:

```ruby
    @articles = Article.search params[:q], :page => (params[:page] || 1)
```

OK. Chances are, you have lots of records stored in your database. How will you get them to _ElasticSearch_? Easy:

```ruby
    Article.index.import Article.all
```

This way, however, all your records are loaded into memory, serialized into JSON,
and sent down the wire to _ElasticSearch_. Not practical, you say? You're right.

Provided your model implements some sort of _pagination_ — and it probably does —, you can just run:

```ruby
    Article.import
```

In this case, the `Article.paginate` method is called, and your records are sent to the index
in chunks of 1000. If that number doesn't suit you, just provide a better one:

```ruby
    Article.import :per_page => 100
```

Any other parameters you provide to the `import` method are passed down to the `paginate` method.

Are we saying you have to fiddle with this thing in a `rails console` or silly Ruby scripts? No.
Just call the included _Rake_ task on the commandline:

```bash
    $ rake environment tire:import CLASS='Article'
```

You can also force-import the data by deleting the index first (and creating it with mapping
provided by the `mapping` block in your model):

```bash
    $ rake environment tire:import CLASS='Article' FORCE=true
```

When you'll spend more time with _ElasticSearch_, you'll notice how
[index aliases](http://www.elasticsearch.org/guide/reference/api/admin-indices-aliases.html)
are the best idea since the invention of inverted index.
You can index your data into a fresh index (and possibly update an alias once everything's fine):

```bash
    $ rake environment tire:import CLASS='Article' INDEX='articles-2011-05'
```

OK. All this time we have been talking about `ActiveRecord` models, since
it is a reasonable _Rails_' default for the storage layer.

But what if you use another database such as [MongoDB](http://www.mongodb.org/),
another object mapping library, such as [Mongoid](http://mongoid.org/)?

Well, things stay mostly the same:

```ruby
    class Article
      include Mongoid::Document
      field :title, :type => String
      field :content, :type => String

      include Tire::Model::Search
      include Tire::Model::Callbacks

      # Let's use a different index name so stuff doesn't get mixed up
      #
      index_name 'mongo-articles'

      # These Mongo guys sure do some funky stuff with their IDs
      # in +serializable_hash+, let's fix it.
      #
      def to_indexed_json
        self.to_json
      end

    end

    Article.create :title => 'I Love ElasticSearch'

    Article.search 'love'
```

_Tire_ does not care what's your primary data storage solution, if it has an _ActiveModel_-compatible
adapter. But there's more.

_Tire_ implements not only _searchable_ features, but also _persistence_ features. This means you can use a _Tire_ model **instead of your database**, not just for _searching_ your database. Why would you like to do that?

Well, because you're tired of database migrations and lots of hand-holding with your
database to store stuff like `{ :name => 'Tire', :tags => [ 'ruby', 'search' ] }`.
Because what you need is to just dump a JSON-representation of your data into a database and
load it back when needed.
Because you've noticed that _searching_ your data is a much more effective way of retrieval
then constructing elaborate database query conditions.
Because you have _lots_ of data and want to use _ElasticSearch's_
advanced distributed features.

To use the persistence features, just include the `Tire::Persistence` module in your class and define the properties (like with _CouchDB_- or _MongoDB_-based models):

```ruby
    class Article
      include Tire::Model::Persistence
      include Tire::Model::Search
      include Tire::Model::Callbacks

      validates_presence_of :title, :author

      property :title
      property :author
      property :content
      property :published_on
    end
```

Of course, not all validations or `ActionPack` helpers will be available to your models,
but if you can live with that, you've just got a schema-free, highly-scalable storage
and retrieval engine for your data.

This will result in Article instances being stored in an index called 'test_articles' when used in tests but in the index 'development_articles' when used in the development environment.

Please be sure to peruse the [integration test suite](https://github.com/karmi/tire/tree/master/test/integration)
for examples of the API and _ActiveModel_ integration usage.


Extensions and Additions
------------------------

The [_tire-contrib_](http://github.com/karmi/tire-contrib/) project contains additions
and extensions to the _Tire_ functionality.


Todo, Plans & Ideas
-------------------

_Tire_ is already used in production by its authors. Nevertheless, it's not considered finished yet.

There are todos, plans and ideas, some of which are listed below, in the order of importance:

* Proper RDoc annotations for the source code
* [Statistical](http://www.elasticsearch.org/guide/reference/api/search/facets/statistical-facet.html) facets
* [Geo Distance](http://www.elasticsearch.org/guide/reference/api/search/facets/geo-distance-facet.html) facets
* [Index aliases](http://www.elasticsearch.org/guide/reference/api/admin-indices-aliases.html) management
* [Analyze](http://www.elasticsearch.org/guide/reference/api/admin-indices-analyze.html) API support
* Embedded webserver to display statistics and to allow easy searches


Other Clients
-------------

Check out [other _ElasticSearch_ clients](http://www.elasticsearch.org/guide/appendix/clients.html).


Feedback
--------

You can send feedback via [e-mail](mailto:karmi@karmi.cz) or via [Github Issues](https://github.com/karmi/tire/issues).

-----

[Karel Minarik](http://karmi.cz) and [contributors](http://github.com/karmi/tire/contributors)
