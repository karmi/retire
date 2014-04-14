module Tire
  module Search
    class Query

      def function_score(&block)
        @function_score = FunctionScoreQuery.new
        block.arity < 1 ? @function_score.instance_eval(&block) : block.call(@function_score) if
          block_given?
        @value[:function_score] = @function_score.to_hash
        @value
      end

      class FunctionScoreQuery
        class CustomFilter
          def initialize(&block)
            @value = {}
            block.arity < 1 ? self.instance_eval(&block) : block.call(self) if block_given?
          end

          def filter(type, *options)
            @value[:filter] = Filter.new(type, *options).to_hash
            @value
          end

          def boost_factor(value)
            @value[:boost_factor] = value
            @value
          end

          def script(value)
            @value[:script] = value
            @value
          end

          def to_hash
            @value
          end

          def to_json
            to_hash.to_json
          end
        end

        def initialize(&block)
          @value = {}
          block.arity < 1 ? self.instance_eval(&block) : block.call(self) if block_given?
        end

        def query(options={}, &block)
          @value[:query] = Query.new(&block).to_hash
          @value
        end

        def filter(&block)
          custom_filter = CustomFilter.new
          block.arity < 1 ? custom_filter.instance_eval(&block) : block.call(custom_filter) if block_given?
          @value[:functions] ||= []
          @value[:functions] << custom_filter.to_hash
          @value
        end

        def score_mode(value)
          @value[:score_mode] = value
          @value
        end

        def boost_mode(value)
          @value[:boost_mode] = value
          @value
        end

        def max_boost(value)
          @value[:max_boost] = value
          @value
        end

        def params(value)
          @value[:params] = value
          @value
        end

        def to_hash
          @value[:functions] ?
          @value :
          @value.merge(:functions => [CustomFilter.new{ filter(:match_all); boost_factor(1) }.to_hash]) # Needs at least one filter
        end

        def to_json
          to_hash.to_json
        end
      end
    end
  end
end
