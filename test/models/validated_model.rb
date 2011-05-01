# Example ActiveModel with validations

class ValidatedModel

  include Tire::Model::Persistence

  property :name

  validates_presence_of :name

end
