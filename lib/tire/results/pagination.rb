module Tire
  module Results

    module Pagination

      def total_entries
        @total
      end

      def total_pages
        result = @total.to_f / (@options[:per_page] || @options[:size] || 10 ).to_i
        result < 1 ? 1 : result.ceil
      end

      def current_page
        if @options[:page]
          @options[:page].to_i
        else
          (@options[:size].to_i + @options[:from].to_i) / @options[:size].to_i
        end
      end

      def previous_page
        current_page - 1
      end

      def next_page
        current_page + 1
      end

    end

  end
end
