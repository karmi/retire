# ActiveModel::Serialization Ruby < 1.9.x compatibility

class Symbol
  def <=> other
    self.to_s <=> other.to_s
  end unless method_defined?(:'<=>')

  def capitalize
    to_s.capitalize
  end unless method_defined?(:capitalize)
end
