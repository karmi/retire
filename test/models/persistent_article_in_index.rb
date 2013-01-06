# Example class with Elasticsearch persistence in index `persistent_articles`
#
# The `index` is `persistent_articles`
#

class PersistentArticleInIndex

  include Tire::Model::Persistence

  property :title
  property :published_on
  property :tags

  index_name "persistent_articles"

end
