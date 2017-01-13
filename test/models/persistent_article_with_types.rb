class PersistentArticleWithTypes

  include Tire::Model::Persistence

  property :title, :type => 'string'
  property :comment_count, :type => 'integer'
  property :average_score, :type => 'float'

end
