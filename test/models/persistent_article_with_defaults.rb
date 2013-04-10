class PersistentArticleWithDefaults

  include Tire::Model::Persistence

  property :title
  property :published_on
  property :tags,       :default => []
  property :hidden,     :default => false
  property :options,    :type => 'object', :default => {:switches => []}
  property :created_at, :default => lambda { Time.now }

end
