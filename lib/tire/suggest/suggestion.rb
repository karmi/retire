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
        self
      end

      def completion(value, options={})
        @value[:completion] = {:field => value}.update(options)
        self
      end

      def term(value, options={})
        @value[:term] = { :field => value }.update(options)
        self
      end

      def phrase(field, options={}, &block)
        @value[:phrase] = PhraseSuggester.new(field, options, &block).to_hash
        self
      end

      def to_hash
        {@name.to_sym => @value}
      end

      def to_json(options={})
        to_hash.to_json
      end

    end

    # Used to generate phrase suggestions
    class PhraseSuggester

      def initialize(field, options={}, &block)
        @options = options
        @value   = { :field => field }
        block.arity < 1 ? self.instance_eval(&block) : block.call(self) if block_given?
      end

      def generator(field, options={})
        @generators ||= []
        @generators << { :field => field }.update(options).to_hash
        self
      end

      def smoothing(type, options={})
        @value[:smoothing] = { type => options }
      end

      def to_json(options={})
        to_hash.to_json
      end

      def to_hash
        @value.update(@options)
        @value.update( { :direct_generator => @generators } ) if @generators && @generators.size > 0

        @value
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