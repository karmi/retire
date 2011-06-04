class Hash

  def to_json
    MultiJson.encode(self)
  end

  alias_method :to_indexed_json, :to_json
end
