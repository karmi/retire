# Example class with ElasticSearch persistence

class PersistentArticle

  include Slingshot::Model::Persistence

  property :title
  property :published_on
  property :tags

end
