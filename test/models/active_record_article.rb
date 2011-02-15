require 'rubygems'
require 'active_record'

class ActiveRecordArticle < ActiveRecord::Base
  include Slingshot::Model::Search
  include Slingshot::Model::Callbacks
end
