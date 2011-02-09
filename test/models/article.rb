# Example non-ActiveModel custom wrapper for result item

class Article
  attr_reader :title, :body

  def initialize(attributes={})
    attributes.each { |k,v| instance_variable_set(:"@#{k}", v) }
  end

  def to_json
    { :title => @title, :body => @body }.to_json
  end

  alias :to_indexed_json :to_json
end
