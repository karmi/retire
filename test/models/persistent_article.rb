# Example class with ElasticSearch persistence

class PersistentArticle

  include Slingshot::Model::Persistence
  include Slingshot::Model::Search
  include Slingshot::Model::Callbacks

  property :published

end
