Tire
=========

_Tire_ is a Ruby client for the [ElasticSearch](http://www.elasticsearch.org/) search engine/database.

_ElasticSearch_ is a scalable, distributed, cloud-ready, highly-available,
full-text search engine and database, communicating by JSON over RESTful HTTP,
based on [Lucene](http://lucene.apache.org/), written in Java.

This document provides just a brief overview of _Tire's_ features. Be sure to check out also
the extensive documentation at <http://karmi.github.com/tire/> if you're interested.

Installation
------------

First, you need a running _ElasticSearch_ server. Thankfully, it's easy. Let's define easy:

    $ curl -k -L -o elasticsearch-0.16.0.tar.gz http://github.com/downloads/elasticsearch/elasticsearch/elasticsearch-0.16.0.tar.gz
    $ tar -zxvf elasticsearch-0.16.0.tar.gz
    $ ./elasticsearch-0.16.0/bin/elasticsearch -f

OK. Easy. On a Mac, you can also use _Homebrew_:

    $ brew install elasticsearch

OK. Let's install the gem via Rubygems:

    $ gem install tire

Of course, you can install it from the source as well:

    $ git clone git://github.com/karmi/tire.git
    $ cd tire
    $ rake install


Usage
-----

_Tire_ exposes easy-to-use domain specific language for fluent communication with _ElasticSearch_.

It also blends with your [ActiveModel](https://github.com/rails/rails/tree/master/activemodel)
classes for convenient usage in Rails applications.

To test-drive the core _ElasticSearch_ functionality, let's require the gem:

```ruby
    require 'rubygems'
    require 'tire'
```

Please note that you can copy these snippets from the much more extensive and heavily annotated file
in [examples/tire-dsl.rb](http://karmi.github.com/tire/).

OK. Let's create an index named `articles` and store/index some documents:

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
one by one. We can use _ElasticSearch's_ [bulk storage](http://www.elasticsearch.org/guide/reference/api/bulk.html):

```ruby
    articles = [
      { :id => '1', :title => 'one'   },
      { :id => '2', :title => 'two'   },
      { :id => '3', :title => 'three' }
    ]

    Tire.index 'bulk' do
      import articles
    end
```

We can also easily manipulate the documents before storing them in the index, by passing a block to the
`import` method:

```ruby
    Tire.index 'bulk' do
      import articles do |documents|

        documents.each { |document| document[:title].capitalize! }
      end
    end
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

      sort { title 'desc' }

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

If configuring the search payload with a block somehow feels too weak for you, you can simply pass
a Ruby `Hash` (or JSON string) with the query declaration to the `search` method:

```ruby
    Tire.search 'articles', :query => { :fuzzy => { :title => 'Sour' } }
```

If this sounds like a great idea to you, you are probably able to write your application
using just `curl`, `sed` and `awk`.

We can display the full query JSON for close inspection:

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
for smooth iterating and displaying the results.

You may wrap the result items in your own class by setting the `Tire.configuration.wrapper`
property. Your class must take a `Hash` of attributes on initialization.

If that seems like a great idea to you, there's a big chance you already have such class, and one would bet
it's an `ActiveRecord` or `ActiveModel` class, containing model of your Rails application.

Fortunately, _Tire_ makes blending _ElasticSearch_ features into your models trivially possible.


ActiveModel Integration
-----------------------

If you're the type with no time for lengthy introductions, you can generate a fully working
example Rails application, with an `ActiveRecord` model and a search form, to play with:

    $ rails new searchapp -m https://github.com/karmi/tire/raw/master/examples/rails-application-template.rb

For the rest, let's suppose you have an `Article` class in your Rails application.
To make it searchable with _Tire_, you just `include` it:

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

it is automatically added into the index, because of the included callbacks.
(You may want to skip them in special cases, like when your records are indexed via some external
mechanism, let's say CouchDB or RabbitMQ [river](http://www.elasticsearch.org/blog/2010/09/28/the_river.html)
for _ElasticSearch_.)

The document attributes are indexed exactly as when you call the `Article#to_json` method.

Now you can search the records:

```ruby
    Article.search 'love'
```

OK. This is where the game stops, often. Not here.

First of all, you may use the full query DSL, as explained above, with filters, sorting,
advanced facet aggregation, highlighting, etc:

```ruby
    q = 'love'
    Article.search do
      query { string q }
      facet('timeline') { date :published_on, :interval => 'month' }
      sort  { published_on 'desc' }
    end
```

Dynamic mapping is a godsend when you're prototyping.
For serious usage, though, you'll definitely want to define a custom mapping for your model:

```ruby
    class Article < ActiveRecord::Base
      include Tire::Model::Search
      include Tire::Model::Callbacks

      mapping do
        indexes :id,           :type => 'string',  :analyzed => false
        indexes :title,        :type => 'string',  :analyzer => 'snowball', :boost => 100
        indexes :content,      :type => 'string',  :analyzer => 'snowball'
        indexes :author,       :type => 'string',  :analyzer => 'keyword'
        indexes :published_on, :type => 'date',    :include_in_all => false
      end
    end
```

In this case, _only_ the defined model attributes are indexed when adding to the index.

When you want tight grip on how your model attributes are added to the index, just
provide the `to_indexed_json` method yourself:

```ruby
    class Article < ActiveRecord::Base
      include Tire::Model::Search
      include Tire::Model::Callbacks

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

Note that _Tire_-enhanced models are fully compatible with [`will_paginate`](https://github.com/mislav/will_paginate),
so you can pass any parameters to the `search` method in the controller, as usual:

```ruby
    @articles = Article.search params[:q], :page => (params[:page] || 1)
```

OK. Chances are, you have lots of records stored in the underlying database. How will you get them to _ElasticSearch_? Easy:

```ruby
    Article.elasticsearch_index.import Article.all
```

However, this way, all your records are loaded into memory, serialized into JSON,
and sent down the wire to _ElasticSearch_. Not practical, you say? You're right.

Provided your model implements some sort of _pagination_ — and it probably does, for so much data —,
you can just run:

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

    $ rake environment tire:import CLASS='Article'

You can also force-import the data by deleting the index first (and creating it with mapping
provided by the `mapping` block in your model):

    $ rake environment tire:import CLASS='Article' FORCE=true

When you'll spend more time with _ElasticSearch_, you'll notice how
[index aliases](http://www.elasticsearch.org/guide/reference/api/admin-indices-aliases.html)
are the best idea since the invention of inverted index.
You can index your data into a fresh index (and possibly update an alias if everything's fine):

    $ rake environment tire:import CLASS='Article' INDEX='articles-2011-05'

OK. All this time we have been talking about `ActiveRecord` models, since
it is a reasonable Rails' default for the storage layer.

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

That's kinda nice. But there's more.

_Tire_ implements not only _searchable_ features, but also _persistence_ features.

This means that you can use a _Tire_ model **instead of** your database, not just
for searching your database. Why would you like to do that?

Well, because you're tired of database migrations and lots of hand-holding with your
database to store stuff like `{ :name => 'Tire', :tags => [ 'ruby', 'search' ] }`.
Because what you need is to just dump a JSON-representation of your data into a database and
load it back when needed.
Because you've noticed that _searching_ your data is a much more effective way of retrieval
then constructing elaborate database query conditions.
Because you have _lots_ of data and want to use _ElasticSearch's_
advanced distributed features.

To use the persistence features, you have to include the `Tire::Persistence` module
in your class and define the properties (analogous to the way you do with CouchDB- or MongoDB-based models):

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

Todo, Plans & Ideas
-------------------

_Tire_ is already used in production by its authors. Nevertheless, it's not considered finished yet.

There are todos, plans and ideas, some of which are listed below, in the order of importance:

* Wrap all Tire functionality mixed into a model in a "forwardable" object, and proxy everything via this object. (The immediate problem: [Mongoid](http://mongoid.org/docs/indexing.html))
* If we're not stepping on other's toes, bring Tire methods like `index`, `search`, `mapping` also to the class/instance top-level namespace.
* Proper RDoc annotations for the source code
* [Histogram](http://www.elasticsearch.org/guide/reference/api/search/facets/histogram-facet.html) facets
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

[Karel Minarik](http://karmi.cz)
