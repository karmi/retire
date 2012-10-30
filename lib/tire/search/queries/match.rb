module Tire
  module Search
    class Query

      def match(field, value, options={})
        if @value.empty?
          @value = MatchQuery.new(field, value, options).to_hash
        else
          MatchQuery.add(self, field, value, options)
        end
        @value
      end
    end

    class MatchQuery
      def initialize(field, value, options={})
        query_options = { :query => value }.merge(options)

        if field.is_a?(Array)
          @value = { :multi_match => query_options.merge( :fields => field ) }
        else
          @value = { :match => { field => query_options } }
        end
      end

      def self.add(query, field, value, options={})
        unless query.value[:bool]
          original_value = query.value.dup
          query.value = { :bool => {} }
          (query.value[:bool][:must] ||= []) << original_value
        end
        query.value[:bool][:must] << MatchQuery.new(field, value, options).to_hash
      end

      def to_hash
        @value
      end
    end
  end
end
