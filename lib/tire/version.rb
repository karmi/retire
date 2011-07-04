module Tire
  VERSION          = "0.1.15"

  CHANGELOG =<<-END
    IMPORTANT CHANGES LATELY:

    # Cleanup of code for getting document type, id, JSON serialization
    # Bunch of deprecations: sorting, passing document type to store/remove
    # Displaying a warning when no ID is passed when storing in bulk
    # Correct handling of import for Mongoid/Kaminari combos
  END
end
