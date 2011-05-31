# Example ActiveModel class with custom index name

require File.expand_path('../active_model_article', __FILE__)

class ActiveModelArticleWithCustomIndexName < ActiveModelArticle
  index_name 'custom-index-name'
end
