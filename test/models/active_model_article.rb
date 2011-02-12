# Example ActiveModel class
require 'rubygems'
require 'active_model'

class ActiveModelArticle
  include ActiveModel::AttributeMethods
  include ActiveModel::Validations
  include ActiveModel::Serialization
  include ActiveModel::Serializers::JSON
  include ActiveModel::Naming

  include Slingshot::Model::Search

  attr_reader :attributes

  def initialize(attributes = {})
    @attributes = attributes
  end

  def method_missing(id, *args, &block)
    attributes[id.to_sym] || attributes[id.to_s] || super
  end

end
