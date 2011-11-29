require 'rest_client'
require 'multi_json'
require 'active_model'
require 'hashr'

require 'tire/rubyext/hash'
require 'tire/rubyext/symbol'
require 'tire/logger'
require 'tire/configuration'
require 'tire/http/response'
require 'tire/http/client'
require 'tire/search'
require 'tire/search/query'
require 'tire/search/sort'
require 'tire/search/facet'
require 'tire/search/filter'
require 'tire/search/highlight'
require 'tire/results/pagination'
require 'tire/results/collection'
require 'tire/results/item'
require 'tire/index'
require 'tire/dsl'
require 'tire/model/naming'
require 'tire/model/callbacks'
require 'tire/model/percolate'
require 'tire/model/indexing'
require 'tire/model/import'
require 'tire/model/search'
require 'tire/model/persistence/finders'
require 'tire/model/persistence/attributes'
require 'tire/model/persistence/storage'
require 'tire/model/persistence'
require 'tire/tasks'

module Tire
  extend DSL

  def warn(message)
    line = caller.detect { |line| line !~ %r|lib\/tire\/| }.sub(/:in .*/, '')
    STDERR.puts  "", "\e[31m[DEPRECATION WARNING] #{message}", "(Called from #{line})", "\e[0m"
  end
  module_function :warn
end
