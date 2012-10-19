module Tire
  module Search

    # http://www.elasticsearch.org/guide/reference/api/search/highlighting.html
    #
    class Highlight

      def initialize(*args)
        @options  = (args.last.is_a?(Hash) && args.last.delete(:options)) || {}
        extract_highlight_tags
        @fields   = args.inject({}) do |result, field|
          field.is_a?(Hash) ? result.update(field) : result[field.to_sym] = {}; result
        end
      end

      def to_json(options={})
        to_hash.to_json
      end

      def to_hash
        { :fields => @fields }.update @options
      end

      private

      def extract_highlight_tags
        if tag = @options.delete(:tag)
          @options.update \
            :pre_tags  => [tag],
            :post_tags => [tag.to_s.gsub(/^<([a-z]+).*/, '</\1>')]
        end
      end

    end

  end
end
