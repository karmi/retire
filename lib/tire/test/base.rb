module Tire::Model::Search

  def reset_model_indexes
    models.each do |model|
      model.tire.index.delete
      model.tire.index.create
    end
  end

end
