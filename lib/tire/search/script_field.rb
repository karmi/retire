module Tire
  module Search

    # http://www.elasticsearch.org/guide/reference/api/search/script-fields.html
    # http://www.elasticsearch.org/guide/reference/modules/scripting.html

    class ScriptField

      def initialize(name, options)
        @hash = { name => options }
      end

      def to_json(options={})
        to_hash.to_json
      end

      def to_hash
        @hash
      end
    end

  end
end
