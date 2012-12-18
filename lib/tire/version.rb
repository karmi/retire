module Tire
  VERSION   = "0.5.2"

  CHANGELOG =<<-END
    IMPORTANT CHANGES LATELY:

    * Fixed bugs in the `matches` Tire method in models
    * Fixed JSON parser errors when logging empty bodies
    * Allow arbitrary ordering of methods in the facet DSL block
    * Fix issues with Mongoid gem (incorrect JSON serialization of Moped::BSON::ObjectId)
  END
end
