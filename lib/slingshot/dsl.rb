module Slingshot
  module DSL

    def search(indices, &block)
      Search::Search.new(indices, &block).perform
    end

    def index(name, &block)
      Index.new(name, &block)
    end

  end
end
