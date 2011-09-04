module Tire
  VERSION   = "0.3.2"

  CHANGELOG =<<-END
    IMPORTANT CHANGES LATELY:

    0.2.0
    ---------------------------------------------------------
    # By default, results are wrapped in Item class
    # Completely rewritten ActiveModel/ActiveRecord support
    # Added infrastructure for loading "real" models from database (eagerly or in runtime)
    # Deprecated the dynamic sort methods in favour of the 'sort { by :field_name }' syntax

    0.2.1
    ---------------------------------------------------------
    # Lighweight check for index presence
    # Added the 'settings' method for models to define index settings
    # Fixed errors when importing data with will_paginate vs Kaminari (MongoDB)
    # Added support for histogram facets [Paco Guzman]

    0.3.0
    ---------------------------------------------------------
    # Isolated Tire ActiveModel integration into `tire` class and instance method.
    
      When there's no conflict with existing methods, Tire methods are added
      to the class namespace, as well, so the change is 100% backwards-compatible.
  END
end
