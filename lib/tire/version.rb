module Tire
  VERSION          = "0.1.13"

  CHANGELOG =<<-END
    IMPORTANT CHANGES LATELY:

    # Added `<after/before>_update_elastic_search_index` callbacks for models
    # Search performs GET instead of POST
    # Added percolator support
    # Added percolator support for models
    # CHANGELOG support in gemspec
    # [FIX] Do not redefine #to_hash in models
    # [FIX] Added that MyModel#update_elastic_search_index sets _index, _type, _version properties
  END
end
