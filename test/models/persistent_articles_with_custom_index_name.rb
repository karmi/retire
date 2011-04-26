# Example class with ElasticSearch persistence and custom index name

class PersistentArticleWithCustomIndexName

  include Slingshot::Model::Persistence

  property :title

  index_name 'custom-index-name'
end
