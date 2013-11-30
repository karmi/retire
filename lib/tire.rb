require 'rest_client'
require 'multi_json'
require 'active_model'
require 'hashr'
require 'cgi'

require 'active_support/core_ext/object/to_param'
require 'active_support/core_ext/object/to_query'
require 'active_support/core_ext/hash/except'
require 'active_support/json'

# Ruby 1.8 compatibility
require 'tire/rubyext/ruby_1_8' if defined?(RUBY_VERSION) && RUBY_VERSION < '1.9'

require 'tire/version'
require 'tire/rubyext/hash'
require 'tire/rubyext/symbol'
require 'tire/utils'
require 'tire/logger'
require 'tire/configuration'
require 'tire/http/response'
require 'tire/http/client'
require 'tire/search'
require 'tire/search/query'
require 'tire/search/queries/match'
require 'tire/search/queries/custom_filters_score'
require 'tire/search/sort'
require 'tire/search/facet'
require 'tire/search/filter'
require 'tire/search/highlight'
require 'tire/search/scan'
require 'tire/search/script_field'
require 'tire/suggest'
require 'tire/suggest/suggestion'
require 'tire/delete_by_query'
require 'tire/multi_search'
require 'tire/count'
require 'tire/results/pagination'
require 'tire/results/collection'
require 'tire/results/item'
require 'tire/results/suggestions'
require 'tire/index'
require 'tire/alias'
require 'tire/dsl'
require 'tire/model/naming'
require 'tire/model/callbacks'
require 'tire/model/percolate'
require 'tire/model/indexing'
require 'tire/model/import'
require 'tire/model/suggest'
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
