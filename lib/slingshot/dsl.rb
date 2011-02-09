module Slingshot
  module DSL

    def configure(&block)
      Configuration.class_eval(&block)
    end

    def search(indices, options={}, &block)
      Search::Search.new(indices, options, &block).perform
    end

    def index(name, &block)
      Index.new(name, &block)
    end

  end
end
