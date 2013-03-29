module Tire
  VERSION   = "0.5.7"

  CHANGELOG =<<-END
    IMPORTANT CHANGES LATELY:

    * Added support for the `constant_score` query
    * Prevent `Curl::Err::MultiBadEasyHandle` errors in the Curb client
    * Refactored the model importing integration and Rake tasks
    * Enabled passing options to the `terms` query
  END
end
