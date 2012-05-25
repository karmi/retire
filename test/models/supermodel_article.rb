# Example ActiveModel class for testing :searchable mode

require 'rubygems'
require 'redis/persistence'

class SupermodelArticle
  include Redis::Persistence

  include Tire::Model::Search
  include Tire::Model::Callbacks

  property :title

  tire do
    settings :number_of_shards => 1, :number_of_replicas => 0

    mapping do
      indexes :title,      :type => 'string', :boost => 15, :analyzer => 'czech'
    end
  end
end
