module Slingshot
  module Search
  
    class Search

      attr_reader :indices

      def initialize(indices, &block)
        @indices = indices
        instance_eval(&block)
      end

    end

  end
end
