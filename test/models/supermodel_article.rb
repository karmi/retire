# Example ActiveModel class for testing :searchable mode

require 'rubygems'
require 'supermodel'

class SupermodelArticle < SuperModel::Base
  include SuperModel::RandomID

  include Slingshot::Model::Search


  alias :persisted? :exists?

  def destroyed?
    !self.class.find(self.id) rescue true
  end

  class << self
    alias :original_find :find
    def find(args)
      if args.is_a?(Array)
        args.map { |id| original_find(id) }
      else
        original_find(args)
      end
    end
  end

end
