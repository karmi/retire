require 'rest_client'
require 'multi_json'
require 'hashr'
require 'cgi'

require 'active_support/core_ext'

# Ruby 1.8 compatibility
require 'tire/rubyext/ruby_1_8' if defined?(RUBY_VERSION) && RUBY_VERSION < '1.9'
require 'tire/rubyext/to_json'
require 'tire/utils'
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
require 'tire/search/scan'
require 'tire/results/pagination'
require 'tire/results/collection'
require 'tire/results/item'
require 'tire/index'
require 'tire/alias'
require 'tire/dsl'
require 'tire/tasks'

module Tire
  extend DSL

  def warn(message)
    line = caller.detect { |line| line !~ %r|lib\/tire\/| }.sub(/:in .*/, '')
    STDERR.puts  "", "\e[31m[DEPRECATION WARNING] #{message}", "(Called from #{line})", "\e[0m"
  end
  module_function :warn
end
