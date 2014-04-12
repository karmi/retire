# Example namespaced class with Elasticsearch persistence
#
# The `tire_document_type` is `my_namespace/persistent_article_in_namespace`
#

module MyNamespace
  class PersistentArticleInNamespace
    include Tire::Model::Persistence

    property :title
  end
end
