require 'rubygems'
require 'active_record'

class ActiveRecordArticle < ActiveRecord::Base
  include Slingshot::Model::Search
  include Slingshot::Model::Callbacks

  mapping do
    indexes :title,      :type => 'string', :boost => 10, :analyzer => 'snowball'
    indexes :created_at, :type => 'date'
  end
end
