module Tire
  module Search
    class IndexedTermsFilter

      def initialize(type, field, *options)
        value = if options.size < 2
          options.first || {}
        else
          options # An +or+ filter encodes multiple filters as an array
        end

        @hash = { type => { field => value } }
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
