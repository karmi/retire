module Tire
  module Results

  	class Suggestions
      include Enumerable

  		def initialize(response, options={})
        @response = response
        @options = options
        @shards_info ||= @response.delete '_shards'
        @keys ||= @response.keys
      end

      def results
        return [] if failure?
        @results ||= @response
      end

      def keys
        @keys
      end

      def each(&block)
        results.each(&block)
      end

      def size
        results.size
      end

      def options(suggestion=:all)
        if suggestion == :all
          results.map {|k,v| v.map{|s| s['options']}}.flatten
        else
          results[suggestion.to_s].map{|s| s['options']}.flatten
        end
      end

      def texts(suggestion=:all)
        if suggestion == :all
          results.map {|k,v| v.map{|s| s['options'].map {|o| o['text']}}}.flatten
        else
          results[suggestion.to_s].map{|s| s['options'].map {|o| o['text']}}.flatten
        end
      end

      def payloads(suggestion=:all)
        if suggestion == :all
          results.map {|k,v| v.map{|s| s['options'].map {|o| o['payload']}}}.flatten
        else
          results[suggestion.to_s].map{|s| s['options'].map {|o| o['payload']}}.flatten
        end
      end

      def error
        @response['error']
      end

      def success?
        error.to_s.empty?
      end

      def failure?
        ! success?
      end
  	end
	end
end
