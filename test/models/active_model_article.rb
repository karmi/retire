# Example ActiveModel class

require 'rubygems'
require 'active_model'

class ActiveModelArticle

  include ActiveModel::AttributeMethods
  include ActiveModel::Serialization
  include ActiveModel::Serializers::JSON
  include ActiveModel::Naming

  include Slingshot::Model::Search

  attr_reader :attributes

  def initialize(attributes = {})
    @attributes = attributes
  end

  def id
    attributes['_id'] || attributes['id']
  end

  def method_missing(name, *args, &block)
    attributes[name.to_sym] || attributes[name.to_s] || super
  end

  def persisted?; true; end
  def save;       true; end

end
