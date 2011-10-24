module Tire
  VERSION   = "0.3.8"

  CHANGELOG =<<-END
    IMPORTANT CHANGES LATELY:

    * Fixed a bug: `Results::Item` was referencing Ruby classes incorrectly within Rails
    * Fixed `ZeroDivisionError` for empty result sets
    * Display correct exception on request failure
    * Added support for range queries
    * Added support for mapping options
  END
end
