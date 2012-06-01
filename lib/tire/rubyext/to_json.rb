require 'time'

class Array
  def to_json(options=nil)
    MultiJson.encode(self)
  end unless method_defined? :to_json
end

class Hash
  def to_json(options=nil)
    MultiJson.encode(self)
  end unless method_defined? :to_json

  alias_method :to_indexed_json, :to_json
end

class Time
  def to_json(options=nil)
    %Q/"#{self.iso8601}"/
  end
end
