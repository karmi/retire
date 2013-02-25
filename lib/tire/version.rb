module Tire
  VERSION   = "0.5.4"

  CHANGELOG =<<-END
    IMPORTANT CHANGES LATELY:

    * Added the support for the Count API
    * Escape single quotes in `to_curl` serialization
    * Added JRuby compatibility
    * Added proper `as_json` support for `Results::Collection` and `Results::Item` classes
    * Added extracting the `routing` information in the `Index#store` method
    * Refactored the `update_index` method for search and persistence integration
    * Cast collection properties in Model::Persistence as empty Array by default
    * Allow passing `:index` option to `MyModel.import`
    * Update to Mocha ~> 0.13
    * Update to MultiJson ~> 1.3
  END
end
