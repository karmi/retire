require 'rest_client'
require 'yajl/json_gem'

module Slingshot

  autoload :Configuration, File.dirname(__FILE__) + '/slingshot/configuration'
  autoload :Client,        File.dirname(__FILE__) + '/slingshot/client'
  autoload :RestClient,    File.dirname(__FILE__) + '/slingshot/client'

  autoload :Search,        File.dirname(__FILE__) + '/slingshot/search'

  module Search
    autoload :Query,       File.dirname(__FILE__) + '/slingshot/search/query'
  end
end
