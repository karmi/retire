# Example class with ElasticSearch persistence

class PersistentArticle

  include Slingshot::Model::Persistence
  include Slingshot::Model::Callbacks
  include Slingshot::Model::Search

  property :title
  property :published_on
  property :tags

end
