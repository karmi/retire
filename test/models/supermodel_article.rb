# Example ActiveModel class for testing :searchable mode

require 'rubygems'
require 'supermodel'

class SupermodelArticle < SuperModel::Base
  include SuperModel::RandomID

  include Slingshot::Model::Search
  include Slingshot::Model::Callbacks

  alias :persisted? :exists?

  def destroyed?
    !self.class.find(self.id) rescue true
  end

end
