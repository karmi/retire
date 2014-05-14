class Author
  attr_accessor :first_name, :last_name
  def initialize(article, attributes)
    @first_name = HashWithIndifferentAccess.new(attributes)[:first_name]
    @last_name  = HashWithIndifferentAccess.new(attributes)[:last_name]
  end
end

class Comment
  def initialize(article, params)
    @article = article
    @attributes = HashWithIndifferentAccess.new(params)
  end

  def posted_within
    posted_at - @article.created_at
  end

  def method_missing(method_name, *arguments); @attributes[method_name];                             end
  def as_json(*);                              @attributes;                                          end
end

class PersistentArticleWithCastedItem
  include Tire::Model::Persistence

  property :title
  property :author, :class => Author
  property :stats
end

class PersistentArticleWithCastedCollection
  include Tire::Model::Persistence

  property :title
  property :created_at, :type => 'date'
  property :comments, :class => [Comment]
end
