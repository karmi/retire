module Tire
  VERSION   = "0.5.5"

  CHANGELOG =<<-END
    IMPORTANT CHANGES LATELY:

    * Improved documentation
    * Improved isolation of Tire methods in model integrations
    * Improved handling of times/dates in `Model::Persistence`
    * Added support for "Put Mapping" and "Delete mapping" APIs
    * Added escaping document IDs in URLs
    * Allowed passing URL options when passing search definition as a Hash
  END
end
