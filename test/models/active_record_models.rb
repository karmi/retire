require 'active_record'

class ActiveRecordArticle < ActiveRecord::Base
  has_many :comments, :class_name => "ActiveRecordComment", :foreign_key => "article_id"
  has_many :stats,    :class_name => "ActiveRecordStat",    :foreign_key => "article_id"

  include Tire::Model::Search
  include Tire::Model::Callbacks

  tire do
    mapping do
      indexes :title,      :type => 'string', :boost => 10, :analyzer => 'snowball'
      indexes :created_at, :type => 'date'
      indexes :suggest, :type => :completion,
                        :index_analyzer => :simple,
                        :search_analyzer => :simple,
                        :payloads => true
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
      :suggest      => suggest,

      :comments     => comments.map { |c| { :_type  => 'active_record_comment',
                                            :_id    => c.id,
                                            :author => c.author,
                                            :body   => c.body  } },
      :stats        => stats.map    { |s| { :pageviews  => s.pageviews } }
    }.to_json
  end

  def suggest
    { 
      input: self.title.split(/\W/).reject(&:empty?),
      output: self.title,
      payload: { length: length, comment_authors: comment_authors}
    }
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

class ActiveRecordClassWithTireMethods < ActiveRecord::Base

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

class ActiveRecordClassWithDynamicIndexName < ActiveRecord::Base
  include Tire::Model::Search
  include Tire::Model::Callbacks

  index_name do
    "dynamic" + '_' + "index"
  end
end

# Used in test for multiple class instances in one index,
# and single table inheritance (STI) support.

class ActiveRecordModelOne < ActiveRecord::Base
  include Tire::Model::Search
  include Tire::Model::Callbacks
  self.table_name = 'active_record_model_one'
  index_name 'active_record_model_one'
end

class ActiveRecordModelTwo < ActiveRecord::Base
  include Tire::Model::Search
  include Tire::Model::Callbacks
  self.table_name = 'active_record_model_two'
  index_name 'active_record_model_two'
end

class ActiveRecordAsset < ActiveRecord::Base
  include Tire::Model::Search
  include Tire::Model::Callbacks
end

class ActiveRecordVideo < ActiveRecordAsset
  index_name 'active_record_assets'
end

class ActiveRecordPhoto < ActiveRecordAsset
  index_name 'active_record_assets'
end

# Namespaced ActiveRecord models

module ActiveRecordNamespace
  def self.table_name_prefix
    'active_record_namespace_'
  end
end

class ActiveRecordNamespace::MyModel < ActiveRecord::Base
  include Tire::Model::Search
  include Tire::Model::Callbacks
end

# Model with percolation

class ActiveRecordModelWithPercolation < ActiveRecord::Base
  include Tire::Model::Search
  include Tire::Model::Callbacks

  percolate!
end
