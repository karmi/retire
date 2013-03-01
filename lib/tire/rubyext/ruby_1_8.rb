unless defined?(URI.encode_www_form_component) && defined?(URI.decode_www_form_component)
  require 'tire/rubyext/uri_escape'
end
