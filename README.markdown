Slingshot
=========

![Slingshot](https://github.com/karmi/slingshot/raw/master/slingshot.png)

_Slingshot_ is a Ruby client for the [ElasticSearch](http://www.elasticsearch.org/) search engine/database.

_ElasticSearch_ is a scalable, distributed, cloud-ready, highly-available,
full-text search engine and database, communicating by JSON over RESTful HTTP,
based on [Lucene](http://lucene.apache.org/), written in Java.

This document provides just a brief overview of _Slingshot's_ features. Be sure to check out also
the extensive documentation at <http://karmi.github.com/slingshot/> if you're interested.

Installation
------------

First, you need a running _ElasticSearch_ server. Thankfully, it's easy. Let's define easy:

    $ curl -k -L -o elasticsearch-0.16.0.tar.gz http://github.com/downloads/elasticsearch/elasticsearch/elasticsearch-0.16.0.tar.gz
    $ tar -zxvf elasticsearch-0.16.0.tar.gz
    $ ./elasticsearch-0.16.0/bin/elasticsearch -f

OK. Easy. On a Mac, you can also use _Homebrew_:

    $ brew install elasticsearch

OK. Let's install the gem via Rubygems:

    $ gem install slingshot-rb

Of course, you can install it from the source as well:

    $ git clone git://github.com/karmi/slingshot.git
    $ cd slingshot
    $ rake install


Usage
-----

_Slingshot_ exposes easy-to-use domain specific language for fluent communication with _ElasticSearch_.

It also blends with your [ActiveModel](https://github.com/rails/rails/tree/master/activemodel)
classes for convenient usage in Rails applications.

To test-drive the core _ElasticSearch_ functionality, let's require the gem:

    require 'rubygems'
    require 'slingshot'

Please note that you can copy these snippets from the much more extensive and heavily annotated file
in [examples/slingshot-dsl.rb](http://karmi.github.com/slingshot/).

OK. Let's create an index named `articles` and store/index some documents:

    Slingshot.index 'articles' do
      delete
      create

      store :title => 'One',   :tags => ['ruby']
      store :title => 'Two',   :tags => ['ruby', 'python']
      store :title => 'Three', :tags => ['java']
      store :title => 'Four',  :tags => ['ruby', 'php']

      refresh
    end

We can also create the index with custom
[mapping](http://www.elasticsearch.org/guide/reference/api/admin-indices-create-index.html)
for a specific document type:

    Slingshot.index 'articles' do
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

Of course, we may have large amounts of data, and it may be impossible or impractical to add them to the index
one by one. We can use _ElasticSearch's_ [bulk storage](http://www.elasticsearch.org/guide/reference/api/bulk.html):

    articles = [
      { :id => '1', :title => 'one'   },
      { :id => '2', :title => 'two'   },
      { :id => '3', :title => 'three' }
    ]

    Slingshot.index 'bulk' do
      import articles
    end

We can also easily manipulate the documents before storing them in the index, by passing a block to the
`import` method:

    Slingshot.index 'bulk' do
      import articles do |documents|

        documents.map { |document| document.update(:title => document[:title].capitalize) }
      end
    end

OK. Now, let's go search all the data.

We will be searching for articles whose `title` begins with letter “T”, sorted by `title` in `descending` order,
filtering them for ones tagged “ruby”, and also retrieving some [_facets_](http://www.elasticsearch.org/guide/reference/api/search/facets/)
from the database:

    s = Slingshot.search 'articles' do
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

<small>Of course, we may also page the results with `from` and `size` query options, retrieve only specific fields
or highlight content matching our query, etc.</small>

Let's display the results:

    s.results.each do |document|
      puts "* #{ document.title } [tags: #{document.tags.join(', ')}]"
    end

    # * Two [tags: ruby, python]

Let's display the global facets (distribution of tags across the whole database):

    s.results.facets['global-tags']['terms'].each do |f|
      puts "#{f['term'].ljust(10)} #{f['count']}"
    end

    # ruby       3
    # python     1
    # php        1
    # java       1

Now, let's display the facets based on current query (notice that count for articles
tagged with 'java' is included, even though it's not returned by our query;
count for articles tagged 'php' is excluded, since they don't match the current query):

    s.results.facets['current-tags']['terms'].each do |f|
      puts "#{f['term'].ljust(10)} #{f['count']}"
    end

    # ruby       1
    # python     1
    # java       1

If configuring the search payload with a block somehow feels too weak for you, you can simply pass
a Ruby `Hash` (or JSON string) with the query declaration to the `search` method:

    Slingshot.search 'articles', :query => { :fuzzy => { :title => 'Sour' } }

If this sounds like a great idea to you, you are probably able to write your application
using just `curl`, `sed` and `awk`.

We can display the full query JSON for close inspection:

    puts s.to_json
    # {"facets":{"current-tags":{"terms":{"field":"tags"}},"global-tags":{"global":true,"terms":{"field":"tags"}}},"query":{"query_string":{"query":"title:T*"}},"filter":{"terms":{"tags":["ruby"]}},"sort":[{"title":"desc"}]}

Or, better, we can display the corresponding `curl` command to recreate and debug the request in the terminal:

    puts s.to_curl
    # curl -X POST "http://localhost:9200/articles/_search?pretty=true" -d '{"facets":{"current-tags":{"terms":{"field":"tags"}},"global-tags":{"global":true,"terms":{"field":"tags"}}},"query":{"query_string":{"query":"title:T*"}},"filter":{"terms":{"tags":["ruby"]}},"sort":[{"title":"desc"}]}'

However, we can simply log every search query (and other requests) in this `curl`-friendly format:

    Slingshot.configure { logger 'elasticsearch.log' }

When you set the log level to _debug_:

    Slingshot.configure { logger 'elasticsearch.log', :level => 'debug' }

the JSON responses are logged as well. This is not a great idea for production environment,
but it's priceless when you want to paste a complicated transaction to the mailing list or IRC channel.

The _Slingshot_ DSL tries hard to provide a strong Ruby-like API for the main _ElasticSearch_ features.

By default, _Slingshot_ wraps the results collection in a enumerable `Results::Collection` class,
and result items in a `Results::Item` class, which looks like a child of `Hash` and `Openstruct`,
for smooth iterating and displaying the results.

You may wrap the result items in your own class by setting the `Slingshot.configuration.wrapper`
property. Your class must take a `Hash` of attributes on initialization.

If that seems like a good idea to you, there's great chance you already have such class, and one would bet
it's an `ActiveRecord` or `ActiveModel` class, containing model of your Rails application.

Fortunately, _Slingshot_ makes blending _ElasticSearch_ into your models trivially possible.


ActiveModel Integration
-----------------------

    TODO


Todo, Plans & Ideas
-------------------

_Slingshot_ is already used in production by its authors. Nevertheless, it's not finished yet.

The todos and plans are vast, and the most important are listed below, in the order of importance:

* Seamless _ActiveModel_ compatibility for easy usage in _Rails_ applications (this also means nearly full _ActiveRecord_ compatibility). See the ongoing work in the [`activemodel`](https://github.com/karmi/slingshot/compare/activemodel) branch
* Seamless [will_paginate](https://github.com/mislav/will_paginate) compatibility for easy pagination. Already [implemented](https://github.com/karmi/slingshot/commit/e1351f6) on the `activemodel` branch
* [Mapping](http://www.elasticsearch.org/guide/reference/mapping/) definition for models
* Proper RDoc annotations for the source code
* [Histogram](http://www.elasticsearch.org/guide/reference/api/search/facets/histogram-facet.html) facets
* [Statistical](http://www.elasticsearch.org/guide/reference/api/search/facets/statistical-facet.html) facets
* [Geo Distance](http://www.elasticsearch.org/guide/reference/api/search/facets/geo-distance-facet.html) facets
* [Index aliases](http://www.elasticsearch.org/guide/reference/api/admin-indices-aliases.html) management
* [Analyze](http://www.elasticsearch.org/guide/reference/api/admin-indices-analyze.html) API support
* [Bulk](http://www.elasticsearch.org/guide/reference/api/bulk.html) API
* Embedded webserver to display statistics and to allow easy searches
* Seamless support for [auto-updating _river_ index](http://www.elasticsearch.org/guide/reference/river/couchdb.html) for _CouchDB_ `_changes` feed

The full ActiveModel integration is planned for the 1.0 release.


Other Clients
-------------

Check out [other _ElasticSearch_ clients](http://www.elasticsearch.org/guide/appendix/clients.html).


Feedback
--------

You can send feedback via [e-mail](mailto:karmi@karmi.cz) or via [Github Issues](https://github.com/karmi/slingshot/issues).

-----

[Karel Minarik](http://karmi.cz)
