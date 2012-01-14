class String

  def document_type_classify
    gsub('__', '/').classify
  end unless respond_to?(:tire_classify)

  def index_name_classify(prefix=Tire::Model::Search.index_prefix + '_')
    gsub(/^#{prefix}/, '').gsub('__', '/').classify
  end unless respond_to?(:index_name_classify)

end
