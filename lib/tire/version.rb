module Tire
  VERSION   = "0.5.1"

  CHANGELOG =<<-END
    IMPORTANT CHANGES LATELY:

    * [!BREAKING!] Change format of sort/order in simple model searches to <field>:<direction>
    * [FIX] Remove `page` and `per_page` from parameters sent to elasticsearch
    * [FIX] Remove the `wrapper` options from URL params sent to elasticsearch
    * [FIX] Use `options.delete(:sort)` in model search to halt bubbling of `sort` into URL parameters [#334]
    * Added prettified JSON output for logging requests and responses at the `debug` level
    * Improved the Rake import task
    * Allow passing of arbitrary objects in the `:as` mapping option [#446]
    * Allow to define default values for Tire::Model::Persistence `:as` lambdas
    * Added `@search.results.max_score`
    * Changed the URI escape/unescape compatibility patch to not require Rack
    * Allow using the full DSL in filter facets
    * Allow complex hash options for the `term` query
    * Allow passing Hash-like objects to `terms` query as well
    * Implemented `respond_to?` for `Item`
    * Improved support for Kaminari pagination
    * Added support for the `parent` URL parameter in `Index#store`
    * Added the `min_score` and `track_scores` DSL methods
    * Added support for loading partial fields
    * Added support for boosting query
    * Added the `facet_filter` DSL method
    * Allow passing `routing`, `fields` and `preference` URL parameter to Index#retrieve
    * Allow building the search request step-by-step in Tire's DSL [#496]
    * Added a `match` query type
    * Added support for multisearch (_msearch) and the `Tire.multi_search` DSL method
    * Added support for multi-search in the ActiveModel integration and in Tire::Model::Persistence
    * Added support for create and delete actions for Index#bulk
    * Added support for meta information (`_routing`, `_parent`, etc) in Index#bulk
    * Added support for URL parameters (`refresh`, `consistency`) in Index#bulk
  END
end
