require 'rubygems'
require 'active_record'

class ActiveRecordArticle < ActiveRecord::Base
  has_many :comments, :class_name => "ActiveRecordComment", :foreign_key => "article_id"
  has_many :stats,    :class_name => "ActiveRecordStat",    :foreign_key => "article_id"

  include Tire::Model::Search
  include Tire::Model::Callbacks

  mapping do
    indexes :title,      :type => 'string', :boost => 10, :analyzer => 'snowball'
    indexes :created_at, :type => 'date'

    indexes :comments do
      indexes :author
      indexes :body
    end
  end

  def to_indexed_json
    {
      :title        => title,
      :length       => length,

      :comments     => comments.map { |c| { :_type  => 'active_record_comment',
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

class ActiveRecordComment < ActiveRecord::Base
  belongs_to :article, :class_name => "ActiveRecordArticle", :foreign_key => "article_id"
end

class ActiveRecordStat < ActiveRecord::Base
  belongs_to :article, :class_name => "ActiveRecordArticle", :foreign_key => "article_id"
end
