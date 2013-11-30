module Tire
  module Suggest

    class Suggestion
      attr_accessor :value, :name

      def initialize(name, &block)
        @name = name
        @value = {}
        block.arity < 1 ? self.instance_eval(&block) : block.call(self) if block_given?
      end

      def text(value)
        @value[:text] = value
        @value
      end

      def completion(value)
        @value[:completion] = {field: value}
        @value
      end

      # TODO TERM SUGGEST check http://www.elasticsearch.org/guide/reference/api/search/term-suggest/
      def term(value, options={})
        @value
      end

      # TODO PHRASE SUGGEST http://www.elasticsearch.org/guide/reference/api/search/phrase-suggest/
      def simple_phrase(&block)
        @value
      end

      def to_hash
        {@name.to_sym => @value}
      end

      def to_json(options={})
        to_hash.to_json
      end

	  end

    class MultiSuggestion
      attr_accessor :suggestions

      def initialize(&block)
        @value = {}
        block.arity < 1 ? self.instance_eval(&block) : block.call(self) if block_given?
      end

      def text(value)
        @global_text = value
        self
      end

      def suggestion(name, &block)
        @suggestions ||= {}
        @suggestions.update Suggestion.new(name, &block).to_hash
        self
      end

      def to_hash
        @value.update @suggestions
        @value[:text] = @global_text if @global_text
        @value
      end

      def to_json(options={})
        to_hash.to_json
      end
    end
	end
end