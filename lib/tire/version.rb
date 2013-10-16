module Tire
  VERSION   = "0.6.1"

  CHANGELOG =<<-END
    IMPORTANT CHANGES LATELY:

    * Added support for bulk update
    * Improved Kaminari support
    * Improved the behaviour of `default` properties in Tire::Persistence
    * Added the information about the gem "retirement" and other documentation improvements
    * Fixed errors due to NewRelic's patching of Curl
    * [ACTIVEMODEL] Use Object#id#to_s in `get_id_from_document`
    * Added support for "Delete By Query" API
  END
end
