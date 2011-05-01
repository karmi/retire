# Example ActiveModel class with callbacks

require 'rubygems'
require 'active_model'

class ActiveModelArticleWithCallbacks

  include ActiveModel::AttributeMethods
  include ActiveModel::Validations
  include ActiveModel::Serialization
  include ActiveModel::Serializers::JSON
  include ActiveModel::Naming

  extend  ActiveModel::Callbacks
  define_model_callbacks :save, :destroy

  include Tire::Model::Search
  include Tire::Model::Callbacks

  attr_reader :attributes

  def initialize(attributes = {})
    @attributes = attributes
  end

  def method_missing(id, *args, &block)
    attributes[id.to_sym] || attributes[id.to_s] || super
  end

  def persisted?
    true
  end

  def save
    _run_save_callbacks do
      STDERR.puts "[Saving ...]"
    end
  end

  def destroy
    _run_destroy_callbacks do
      STDERR.puts "[Destroying ...]"
      @destroyed = true
    end
  end

  def destroyed?; !!@destroyed; end

end
