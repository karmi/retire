module Tire
  module Results

  	class Suggestions
      include Enumerable

  		def initialize(response, options={})
        @response = response
        @options = options
      end

      def results
        return [] if failure?
        @results ||= @response
      end
  	end
	end
end
