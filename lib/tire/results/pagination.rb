module Tire
  module Results

    # Adds support for WillPaginate and Kaminari
    #
    module Pagination

      def default_per_page
        10
      end
      module_function :default_per_page

      def total_entries
        @total
      end

      def per_page
        (@options[:per_page] || @options[:size] || default_per_page ).to_i
      end

      def total_pages
        ( @total.to_f / per_page ).ceil
      end

      def current_page
        if @options[:page]
          @options[:page].to_i
        else
          (per_page + @options[:from].to_i) / per_page
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

      # Kaminari support
      #
      alias :limit_value  :per_page
      alias :total_count  :total_entries
      alias :num_pages    :total_pages
      alias :offset_value :offset
      alias :out_of_range? :out_of_bounds?

      def first_page?
        current_page == 1
      end

      def last_page?
        current_page == total_pages
      end


    end

  end
end
