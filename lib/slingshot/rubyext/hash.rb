class Hash
  alias_method :to_indexed_json, :to_json if respond_to?(:to_json)
end
