module Tire
  module Search

    # Adds support for Suggest API in Tire DSL.
    #
    #
    # Example:
    # -------
    #
    #     Tire.search 'articles' do
    #       suggest :term_suggest_name, 'thrree' do
    #         term 'title'
    #       end
    #       suggest :phrase_suggest_name, 'fouur' do
    #         phrase 'title'
    #       end
    #     end
    #
    # For available options for the term and phrase suggest see:
    #
    # * http://www.elasticsearch.org/guide/reference/api/search/suggest/
    #
    #
    class Suggest

      def initialize(name, text, options={}, &block)
        @name    = name
        @options = options
        @value   = { :text => text }
        block.arity < 1 ? self.instance_eval(&block) : block.call(self) if block_given?
      end

      def term(field, options={})
        @value[:term] = { :field => field }.update(options)
        self
      end

      def phrase(field, options={}, &block)
        @value[:phrase] = PhraseSuggester.new(field, options, &block).to_hash
        self
      end

      def to_json(options={})
        to_hash.to_json
      end

      def to_hash
        @value.update @options
        { @name => @value }
      end

    end

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


  end
end