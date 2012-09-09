require 'tire/test/unit'

class Test::Unit::TestCase

  private

  def reset_tire_indexes
    Tire::Model::Search.reset_model_indexes
  end

end
