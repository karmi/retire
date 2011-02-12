# Example ActiveModel class

require 'active_model'

class ActiveModelArticle
  include ActiveModel::AttributeMethods
  include ActiveModel::Validations
  include ActiveModel::Serialization
  include ActiveModel::Serializers::JSON
  include ActiveModel::Naming

  include Slingshot::Model::Search
end
