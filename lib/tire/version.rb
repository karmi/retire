module Tire
  VERSION   = "0.4.0.pre"

  CHANGELOG =<<-END
    IMPORTANT CHANGES LATELY:

    * Added support for property defaults and casting model properties as Ruby objects in Tire::Model::Persistence
    * Added Hashr (http://rubygems.org/gems/hashr) as dependency
    * Changed that search in persistence returns instances of model not Item
    * Fixed errors in the Curb client
    * Re-raise the RestClient::RequestTimeout and RestClient::ServerBrokeConnection exceptions
    * Added the `:as` option for model mapping to dynamically set property value in serialization
    * Prefer ELASTICSEARCH_URL environment variable as the default URL, if present
    * Added the "text" search query
  END
end
