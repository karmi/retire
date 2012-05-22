class PersistentArticleWithDefaults

  include Tire::Model::Persistence

  property :title
  property :published_on, :default => proc { Time.now }
  property :tags,   :default => []
  property :hidden, :default => false
  property :options,  :default => {:switches => []}

end
