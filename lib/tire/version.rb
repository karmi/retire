module Tire
  VERSION   = "0.4.3rc"

  CHANGELOG =<<-END
    IMPORTANT CHANGES LATELY:

    Version 0.4.1
    -------------
    * Added a Index#settings method to retrieve index settings as a Hash
    * Added support for the "scan" search in the Ruby API
    * Added support for reindexing the index documents into new index
    * Added basic support for index aliases
    * Changed, that Index#bulk_store runs against an index endpoint, not against `/_bulk`
    * Refactorings, fixes, Ruby 1.8 compatibility

    Version 0.4.2
    -------------
    * Fixed incorrect handling of PUT requests in the Curb client
    * Fixed, that blocks passed to `Tire::Index.new` or `Tire.index` losed the scope
    * Added `Tire::Alias`, interface and DSL to manage aliases as resources
  END
end
