# Example ActiveModel with validations

class ValidatedModel

  include Slingshot::Model::Persistence

  property :name

  validates_presence_of :name

end
