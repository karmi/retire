# Example class with ElasticSearch persistence and custom index name

class PersistentArticleWithCustomIndexName

  include Slingshot::Model::Persistence
  include Slingshot::Model::Search
  include Slingshot::Model::Callbacks

  property :title

  index_name 'custom-index-name'
end
