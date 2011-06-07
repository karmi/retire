class Hash

  def to_json
    MultiJson.encode(self)
  end unless respond_to?(:to_json)

  def to_indexed_json
    # Wrap instances of File in the Attachment class
    # TODO: Do not modify Hash here, wrap Hashes in a Document instance, similarly
    # TODO: Add support for Array of attachments
    self.each_pair do |key,value| 
      self.store key, Tire::Attachment.new(value) if value.is_a?(File)
      value.each_pair do |k, v|
        value.store k, Tire::Attachment.new(v) if v.is_a?(File)
      end if value.respond_to?(:each_pair)
    end
    self.to_json
  end
end
