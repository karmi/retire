module Tire
  VERSION   = "0.5.8"

  CHANGELOG =<<-END
    IMPORTANT CHANGES LATELY:

    * Fixed, that Model::Persistence uses "string" as the default mapping type
    * Fixed, that Model::Persistence returns true/false for #save and #destroy operations
    * Fixed the `uninitialized constant HRULE` in Rake tasks
    * Fixed `Item#to_hash` functionality to work with Arrays
    * Updated the Rails application template and install instructions
    * Improved the test suite for Travis
  END
end
