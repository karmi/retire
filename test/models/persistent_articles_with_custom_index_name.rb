# Example class with ElasticSearch persistence and custom index name

class PersistentArticleWithCustomIndexName < PersistentArticle
  index_name 'custom-index-name'
end
