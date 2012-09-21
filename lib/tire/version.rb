module Tire
  VERSION   = "0.4.3"

  CHANGELOG =<<-END
    IMPORTANT CHANGES LATELY:

    * Added a prefix query
    * Added support for "script fields" (return a script evaluation for each hit)
    * Added support for the Update API in Tire::Index
    * [FIX] Fixed incorrect `Results::Item#to_hash` serialization
    * 730813f Added support for aggregating over multiple fields in the "terms" facet
    * Added the "Dis Max Query"
    * Added the ability to transform documents when reindexing
  END
end
