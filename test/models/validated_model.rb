# Example ActiveModel with validations

class ValidatedModel

  include Slingshot::Model::Persistence
  include Slingshot::Model::Search
  include Slingshot::Model::Callbacks

  validates_presence_of :name

end
