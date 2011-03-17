module Slingshot
  module Results

    module Pagination

      def total_entries
        @total
      end

      def total_pages
        result = @total.to_f / (@options[:per_page] ? @options[:per_page].to_i : 10 )
        result < 1 ? 1 : result.round
      end

      def current_page
        @options[:page].to_i
      end

      def previous_page
        @options[:page].to_i - 1
      end

      def next_page
        @options[:page].to_i + 1
      end

    end

  end
end
