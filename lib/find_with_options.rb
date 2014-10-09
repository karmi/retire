module FindWithOptions
  def self.for(klass, ids, options = {})
    scope = klass.all
    scope.includes!(options[:include]) if options[:include]
    scope.find(ids)
  end
end
