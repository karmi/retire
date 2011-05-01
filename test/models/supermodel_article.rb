# Example ActiveModel class for testing :searchable mode

require 'rubygems'
require 'supermodel'

class SupermodelArticle < SuperModel::Base
  include SuperModel::RandomID

  include Tire::Model::Search
  include Tire::Model::Callbacks

  mapping do
    indexes :title,      :type => 'string', :boost => 15, :analyzer => 'czech'
  end

  alias :persisted? :exists?

  def destroyed?
    !self.class.find(self.id) rescue true
  end

end
