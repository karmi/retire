module Tire
  VERSION   = "0.3.7"

  CHANGELOG =<<-END
    IMPORTANT CHANGES LATELY:

    * Fixed a bug: `Results::Item` was referencing Ruby classes incorrectly within Rails
    * Added support for the Analyze API (#124)
    * Added support for adding multiple filters (#122)
    * Fixed incorrect passing of options in the `date` and `terms` facets
    * Removed SDoc since it breaks with current RDoc
  END
end
