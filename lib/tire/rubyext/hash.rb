class Hash

  def to_json
    MultiJson.encode(self)
  end unless respond_to?(:to_json)

  def to_indexed_json
    # Wrap instances of File in the Attachment class
    # TODO: Do not modify Hash here, wrap Hashes in a Document instance
    # TODO: Add support for Array of attachments
    self.each_pair do |key,value|
# p [key, value]

      self.store key, Tire::Attachment.new(value).to_hash if value.is_a?(File)
      value.each_pair do |k, v|
# p [k, v]

        value.store k, Tire::Attachment.new(v).to_hash if v.is_a?(File)
      end if value.respond_to?(:each_pair)
    end
    self.to_json
  end
end
