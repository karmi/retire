# Example class with Elasticsearch persistence

class DynamicAuthor

  include Tire::Model::Persistence
  
end

class PersistentArticleWithDynamicCreation
  
  include Tire::Model::Persistence
  
  property :author, :class => DynamicAuthor
  property :tags,   :default => []
  
end
