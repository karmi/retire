module Tire
  module Search

    # Custom Filters Score
    # ==============
    #
    # Author: Jerry Luk <jerryluk@gmail.com>
    #
    #
    # Adds support for "custom_filters_score" queries in Tire DSL.
    #
    # It hooks into the Query class and inserts the custom_filters_score query types.
    #
    #
    # Usage:
    # ------
    #
    # Require the component:
    #
    #     require 'tire/queries/custom_filters_score'
    #
    # Example:
    # -------
    #
    #     Tire.search 'articles' do
    #       query do
    #         custom_filters_score do
    #           query { term :title, 'Harry Potter' }
    #           filter do
    #             filter :match_all
    #             boost 1.1
    #           end
    #           filter do
    #             filter :term, :author => 'Rowling',
    #             script '2.0'
    #           end
    #           score_mode 'total'
    #         end
    #       end
    #     end
    #
    # For available options for these queries see:
    #
    # * <http://www.elasticsearch.org/guide/reference/query-dsl/custom-filters-score-query.html>
    #
    #
    class Query

      def custom_filters_score(&block)
        @custom_filters_score = CustomFiltersScoreQuery.new
        block.arity < 1 ? @custom_filters_score.instance_eval(&block) : block.call(@custom_filters_score) if
          block_given?
        @value[:custom_filters_score] = @custom_filters_score.to_hash
        @value
      end

      class CustomFiltersScoreQuery
        class CustomFilter
          def initialize(&block)
            @value = {}
            block.arity < 1 ? self.instance_eval(&block) : block.call(self) if block_given?
          end

          def filter(type, *options)
            @value[:filter] = Filter.new(type, *options).to_hash
            @value
          end

          def boost(value)
            @value[:boost] = value
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
          @value[:filters] ||= []
          @value[:filters] << custom_filter.to_hash
          @value
        end

        def score_mode(value)
          @value[:score_mode] = value
          @value
        end

        def params(value)
          @value[:params] = value
          @value
        end

        def to_hash
          @value[:filters] ?
          @value :
          @value.merge(:filters => [CustomFilter.new{ filter(:match_all); boost(1) }.to_hash]) # Needs at least one filter
        end

        def to_json
          to_hash.to_json
        end
      end
    end
  end
end
