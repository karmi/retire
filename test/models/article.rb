# Example non-ActiveModel custom wrapper for result item

class Article
  attr_reader :id, :title, :body, :inner_object

  def initialize(attributes={})
    attributes.each { |k,v| instance_variable_set(:"@#{k}", v) }
  end

  def to_json
    { :id => @id, :title => @title, :body => @body }.to_json
  end

  alias :to_indexed_json :to_json
end
