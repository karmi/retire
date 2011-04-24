Slingshot
=========

![Slingshot](https://github.com/karmi/slingshot/raw/master/slingshot.png)

_Slingshot_ is a Ruby client for the [ElasticSearch](http://www.elasticsearch.org/) search engine/database.
It aims to provide rich and comfortable Ruby API in the form of a simple domain-specific language.

_ElasticSearch_ is a scalable, distributed, cloud-ready, highly-available,
RESTful database communicating by JSON over HTTP, based on [Lucene](http://lucene.apache.org/),
written in Java. It manages to be very simple to use and very powerful at the same time.

Installation
------------

First, you need a running _ElasticSearch_ server. Thankfully, it's easy. Let's define easy:

    $ curl -k -L -o elasticsearch-0.15.2.tar.gz http://github.com/downloads/elasticsearch/elasticsearch/elasticsearch-0.15.2.tar.gz
    $ tar -zxvf elasticsearch-0.15.2.tar.gz
    $ ./elasticsearch-0.15.2/bin/elasticsearch -f

OK, easy. Now, install the gem via Rubygems:

    $ gem install slingshot-rb

or from source:

    $ git clone git://github.com/karmi/slingshot.git
    $ cd slingshot
    $ rake install


Usage
-----

Currently, you can use _Slingshot_ via the DSL (eg. by extending your class with it).
Plans for full ActiveModel integration (and other convenience layers) are in progress
(see the [`activemodel`](https://github.com/karmi/slingshot/compare/activemodel) branch).

To kick the tires, require the gem in an IRB session or a Ruby script
(note that you can just run the full example from [`examples/dsl.rb`](https://github.com/karmi/slingshot/blob/master/examples/dsl.rb)):

    require 'rubygems'
    require 'slingshot'

First, let's create an index named `articles` and store/index some documents:

    Slingshot.index 'articles' do
      delete
      create

      store :title => 'One',   :tags => ['ruby']
      store :title => 'Two',   :tags => ['ruby', 'python']
      store :title => 'Three', :tags => ['java']
      store :title => 'Four',  :tags => ['ruby', 'php']

      refresh
    end

We can also create the
index with specific [mapping](http://www.elasticsearch.org/guide/reference/api/admin-indices-create-index.html):

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

Now, let's query the database.

We are searching for articles whose `title` begins with letter “T”, sorted by `title` in `descending` order,
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

We can display the full query JSON:

    puts s.to_json
    # {"facets":{"current-tags":{"terms":{"field":"tags"}},"global-tags":{"global":true,"terms":{"field":"tags"}}},"query":{"query_string":{"query":"title:T*"}},"filter":{"terms":{"tags":["ruby"]}},"sort":[{"title":"desc"}]}

Or, better, we can display the corresponding `curl` command for easy debugging:

    puts s.to_curl
    # curl -X POST "http://localhost:9200/articles/_search?pretty=true" -d '{"facets":{"current-tags":{"terms":{"field":"tags"}},"global-tags":{"global":true,"terms":{"field":"tags"}}},"query":{"query_string":{"query":"title:T*"}},"filter":{"terms":{"tags":["ruby"]}},"sort":[{"title":"desc"}]}'

Since `curl` is the crucial debugging tool in _ElasticSearch_ land, we can log every search query in `curl` format:

    Slingshot.configure { logger 'elasticsearch.log' }


Features
--------

Currently, _Slingshot_ supports main features of the _ElasticSearch_ [Search API](http://www.elasticsearch.org/guide/reference/api/search/request-body.html) and it's [Query DSL](http://www.elasticsearch.org/guide/reference/query-dsl/). In present, it allows you to:

* Create, delete and refresh the index
* Create the index with specific [mapping](http://www.elasticsearch.org/guide/reference/api/admin-indices-create-index.html)
* Store a document in the index
* [Query](https://github.com/karmi/slingshot/blob/master/examples/dsl.rb) the index with the `query_string`, `term`, `terms` and `match_all` types of queries
* [Sort](http://elasticsearch.org/guide/reference/api/search/sort.html) the results by `fields`
* [Filter](http://elasticsearch.org/guide/reference/query-dsl/) the results
* Retrieve the _terms_ and _date histogram_ types of [facets](http://www.elasticsearch.org/guide/reference/api/search/facets/index.html) (other types are high priority)
* [Highlight](http://www.elasticsearch.org/guide/reference/api/search/highlighting.html) matching fields
* Return just specific `fields` from documents
* Page the results with `from` and `size` query options
* Log the `curl`-equivalent of requests and response JSON

See the [`examples/slingshot-dsl.rb`](blob/master/examples/slingshot-dsl.rb) file for the full, working examples.

_Slingshot_ wraps the results in a enumerable `Results::Collection` class, and every result in a `Results::Item` class,
which looks like a child of `Hash` and `Openstruct`, for smooth iterating and displaying the results.

You may wrap the result items in your own class just by setting the `Configuration.wrapper` property,
supposed your class takes a hash of attributes upon initialization, in ActiveModel/ActiveRecord manner.
Please see the files `test/models/article.rb` and `test/unit/results_collection_test.rb` for details.


Todo, Plans & Ideas
-------------------

_Slingshot_ is already used in production by its authors. Nevertheless, it's not finished yet.

The todos and plans are vast, and the most important are listed below, in the order of importance:

* Seamless _ActiveModel_ compatibility for easy usage in _Rails_ applications (this also means nearly full _ActiveRecord_ compatibility). See the ongoing work in the [`activemodel`](https://github.com/karmi/slingshot/compare/activemodel) branch
* Seamless [will_paginate](https://github.com/mislav/will_paginate) compatibility for easy pagination. Already [implemented](https://github.com/karmi/slingshot/commit/e1351f6) on the `activemodel` branch
* [Mapping](http://www.elasticsearch.org/guide/reference/mapping/) definition for models
* Proper RDoc annotations for the source code
* Dual interface: allow to simply pass queries/options for _ElasticSearch_ as a Hash in any method
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
