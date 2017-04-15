module Tire
  module Search
    class Query

      def mlt(term, options={})
        @value = MoreLikeThisQuery.new(term, options).to_hash
        @value
      end
    end

    class MoreLikeThisQuery
      def initialize(term, options={})
        @value = { :more_like_this => {:like_text => term }.merge(options) }
      end

      def to_hash
        @value
      end
    end
  end
end
