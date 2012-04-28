class Hash

  def to_json(options=nil)
    MultiJson.dump(self)
  end unless respond_to?(:to_json)

  alias_method :to_indexed_json, :to_json
end
