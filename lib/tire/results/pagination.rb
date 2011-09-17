module Tire
  module Results

    module Pagination

      def total_entries
        @total
      end

      def per_page
        (@options[:per_page] || @options[:size] || 10 ).to_i
      end

      def total_pages
        ( @total.to_f / per_page ).ceil
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

      def offset
        per_page * (current_page - 1)
      end

      def out_of_bounds?
        current_page > total_pages
      end

      #kaminari support
      def limit_value
        per_page
      end

      def total_count
        @total
      end

      def num_pages
        total_pages
      end

      def offset_value
        offset
      end

    end

  end
end
