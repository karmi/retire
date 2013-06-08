module Tire
  VERSION   = "0.6.0"

  CHANGELOG =<<-END
    IMPORTANT CHANGES LATELY:

    * Fixed incorrect inflection in the Rake import tasks
    * Added support for `geo_distance` facets
    * Added support for the `custom_filters_score` query
    * Added a custom strategy option to <Model.import>
    * Allow the `:wrapper` option to be passed to Tire.search consistently
    * Improved the Mongoid importing strategy
    * Merge returned `fields` with `_source` if both are returned
    * Removed the deprecated `text` query
    * [FIX] Rescue HTTP client specific connection errors in MyModel#create_elasticsearch_index
    * Added support for passing `version` in Tire::Index#store
    * Added support for `_version_type` in Tire::Index#bulk
    * Added ActiveModel::Serializers compatibility
  END
end
