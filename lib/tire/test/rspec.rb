require 'tire/test/base'

module Tire::RSpec

  def reset_tire_indexes
    Tire::Model::Search.reset_model_indexes
  end

end

RSpec.configure do |config|

  config.include Tire::RSpec

  config.before :each do
    reset_model_indexes if example.metadata[:tire]
  end

end
