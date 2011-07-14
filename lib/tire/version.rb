module Tire
  VERSION   = "0.1.16"

  CHANGELOG =<<-END
    IMPORTANT CHANGES LATELY:

    # Defined mapping for nested fields [#56]
    # Mapping type is optional and defaults to "string"
    # Fixed handling of fields returned prefixed by _source from ES [#31]
    # Allow passing the type to search and added that model passes `document_type` to search [@jonkarna, #38]
    # Allow leaving index name empty for searching the whole server
  END
end
