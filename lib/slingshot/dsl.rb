module Slingshot
  module DSL

    def configure(&block)
      Configuration.class_eval(&block)
    end

    def search(indices, &block)
      Search::Search.new(indices, &block).perform
    end

    def index(name, &block)
      Index.new(name, &block)
    end

  end
end
