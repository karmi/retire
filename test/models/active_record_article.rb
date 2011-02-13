require 'rubygems'
require 'active_record'

class ActiveRecordArticle < ActiveRecord::Base
  include Slingshot::Model::Search
end
