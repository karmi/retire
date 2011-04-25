# Example ActiveModel with validations

class ValidatedModel

  include Slingshot::Model::Persistence
  include Slingshot::Model::Search
  include Slingshot::Model::Callbacks

  property :name

  validates_presence_of :name

end
