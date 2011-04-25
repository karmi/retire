# Example class with ElasticSearch persistence

class PersistentArticle

  include Slingshot::Model::Persistence
  include Slingshot::Model::Search
  include Slingshot::Model::Callbacks

  property :title
  property :published_on
  property :tags

end
