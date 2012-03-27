require 'uri'

module Tire
  module Utils

    def escape(s)
      URI.encode_www_form_component(s.to_s)
    end

    def unescape(s)
      s = s.to_s.respond_to?(:force_encoding) ? s.to_s.force_encoding(Encoding::UTF_8) : s.to_s
      URI.decode_www_form_component(s)
    end

    extend self
  end
end
