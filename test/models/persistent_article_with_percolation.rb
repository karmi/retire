class PersistentArticleWithPercolation
  include Tire::Model::Persistence
  property :title
  percolate!
end
