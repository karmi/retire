# Example class with Elasticsearch persistence and strict mapping

class PersistentArticleWithStrictMapping

  include Tire::Model::Persistence

  mapping :dynamic => 'strict' do
    property :title,   :type => 'string'
    property :created, :type => 'date'
  end

  def myproperty
    @myproperty
  end

  def myproperty= value
    self.class.properties << 'myproperty'
    @myproperty = value
  end

  def to_indexed_json
    json = { :title => self.title, :created => self.created }
    json[:myproperty] = 'NOTVALID' if self.myproperty
    json.to_json
  end
end
