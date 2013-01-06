# Example class with Elasticsearch persistence and custom index name

class PersistentArticleWithCustomIndexName

  include Tire::Model::Persistence

  property :title

  index_name 'custom-index-name'
end
