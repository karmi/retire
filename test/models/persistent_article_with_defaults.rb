class PersistentArticleWithDefaults

  include Tire::Model::Persistence

  property :title
  property :published_on
  property :tags, :default => []

end
