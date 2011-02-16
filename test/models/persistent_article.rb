# Example class with ElasticSearch persistence

class PersistentArticle

  include Slingshot::Model::Search
  include Slingshot::Model::Callbacks
  include Slingshot::Model::Persistence

end
