if Gem.available?('yajl-ruby')
  # Load the Yajl JSON library.
  require 'yajl/json_gem'
  
  module JSON
    def self.encode struct, options={}
      Yajl::Encoder.encode struct, options
    end
    
    def self.parse json_string
      Yajl::Parser.parse json_string
    end
  end
  
else
  # Load the default JSON library.
  require 'json'
  
  module JSON
    def self.encode struct, options={}
      JSON.dump struct
    end
  end
end
