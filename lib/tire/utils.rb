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

    def elapsed_to_human(elapsed)
      hour = 60*60
      day  = hour*24

      seconds = sprintf("%1.5f", (elapsed % 60))
      minutes = ((elapsed/60) % 60).to_i
      hours   = (elapsed/hour).to_i

      case elapsed
      when 0..59
        "#{seconds} seconds"
      when 60..hour-1
        "#{minutes} minutes and #{seconds} seconds"
      when hour..day
        "#{hours} hours and #{minutes} minutes"
      else
        "#{hours} hours"
      end
    end

    extend self
  end
end
