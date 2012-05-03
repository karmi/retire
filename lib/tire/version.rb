module Tire
  VERSION   = "0.4.1"

  CHANGELOG =<<-END
    IMPORTANT CHANGES LATELY:

    * Added a Index#settings method to retrieve index settings as a Hash
    * Added support for the "scan" search in the Ruby API
    * Added support for reindexing the index documents into new index
    * Added basic support for index aliases
    * Changed, that Index#bulk_store runs against an index endpoint, not against `/_bulk`
    * Refactorings, fixes, Ruby 1.8 compatibility
  END
end
