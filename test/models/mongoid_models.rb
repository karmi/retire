require 'mongoid'

class MongoidArticle

  include Mongoid::Document


  has_many :comments, :class_name => "MongoidComment", :foreign_key => "article_id"
  has_many :stats,    :class_name => "MongoidStat",    :foreign_key => "article_id"

  include Tire::Model::Search
  include Tire::Model::Callbacks

  tire do
    mapping do
      indexes :title,      :type => 'string', :boost => 10, :analyzer => 'snowball'
      indexes :created_at, :type => 'date'

      indexes :comments do
        indexes :author
        indexes :body
      end
    end
  end

  def to_indexed_json
    {
      :title        => title,
      :length       => length,

      :comments     => comments.map { |c| { :_type  => 'mongoid_comment',
                                            :_id    => c.id,
                                            :author => c.author,
                                            :body   => c.body  } },
      :stats        => stats.map    { |s| { :pageviews  => s.pageviews } }
    }.to_json
  end

  def length
    title.length
  end

  def comment_authors
    comments.map(&:author).to_sentence
  end
end

class MongoidComment

  include Mongoid::Document


  belongs_to :article, :class_name => "MongoidArticle", :foreign_key => "article_id"
end

class MongoidStat

  include Mongoid::Document


  belongs_to :article, :class_name => "MongoidArticle", :foreign_key => "article_id"
end

class MongoidClassWithTireMethods

  include Mongoid::Document


  def self.mapping
    "THIS IS MY MAPPING!"
  end

  def index
    "THIS IS MY INDEX!"
  end

  include Tire::Model::Search
  include Tire::Model::Callbacks

  tire do
    mapping do
      indexes :title, :type => 'string', :analyzer => 'snowball'
    end
  end
end
