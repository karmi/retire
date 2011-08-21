module Tire
  VERSION   = "0.2.0"

  CHANGELOG =<<-END
    IMPORTANT CHANGES LATELY:

    # By default, results are wrapped in Item class (05a1331)
    # Completely rewritten ActiveModel/ActiveRecord support
    # Added method to items for loading the "real" model from database (f9273bc)
    # Added the ':load' option to eagerly load results from database (1e34cde)
    # Deprecated the dynamic sort methods, use the 'sort { by :field_name }' syntax
  END
end
