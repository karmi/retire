# Example namespaced class with ElasticSearch persistence
#
# The `document_type` is `my_namespace/persistent_article_in_namespace`
#

module MyNamespace
  class PersistentArticleInNamespace
    include Tire::Model::Persistence

    property :title
  end
end
