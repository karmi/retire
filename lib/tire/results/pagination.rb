module Tire
  module Results

    module Pagination

      def total_entries
        @total
      end

      def total_pages
        ( @total.to_f / (@options[:per_page] || @options[:size] || 10 ).to_i ).ceil
      end

      def current_page
        if @options[:page]
          @options[:page].to_i
        else
          (@options[:size].to_i + @options[:from].to_i) / @options[:size].to_i
        end
      end

      def previous_page
        current_page > 1 ? (current_page - 1) : nil
      end

      def next_page
        current_page < total_pages ? (current_page + 1) : nil
      end

      def out_of_bounds?
        current_page > total_pages
      end

    end

  end
end
