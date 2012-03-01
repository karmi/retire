# Example ActiveModel class for testing :searchable mode

require 'rubygems'
require 'supermodel'

class SupermodelArticleWithDefaultFilter < SuperModel::Base
  include SuperModel::RandomID

  include Tire::Model::Search
  include Tire::Model::Callbacks

  mapping do
    indexes :title,      :type => 'string', :boost => 15, :analyzer => 'czech'
    indexes :status,      :type => 'string'
  end

  default_search_filter :status => 'active'

  alias :persisted? :exists?

  def destroyed?
    !self.class.find(self.id) rescue true
  end
end
