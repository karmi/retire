require 'uri'

module Tire
  module Utils

    def escape(s)
      URI.encode_www_form_component(s.to_s)
    end

    def unescape(s)
      URI.decode_www_form_component( s.to_s.force_encoding(Encoding::UTF_8) )
    end

    extend self
  end
end
