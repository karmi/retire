module Tire
  module Model

    # Contains support for the [percolation](http://www.elasticsearch.org/guide/reference/api/percolate.html)
    # feature of _Elasticsearch_.
    #
    module Percolate

      module ClassMethods

        # Set up the percolation when documents are being added to the index.
        #
        # Usage:
        #
        #     class Article
        #       # ...
        #       percolate!
        #     end
        #
        # First, you have to register a percolator query:
        #
        #     Article.index.register_percolator_query('fail')    { |query| query.string 'fail' }
        #
        # Then, when you update the index, matching queries are returned in the `matches` property:
        #
        #     p Article.create(:title => 'This is a FAIL!').matches
        #
        #
        # You may pass a pattern to filter which percolator queries will be executed.
        #
        # See <http://www.elasticsearch.org/guide/reference/api/index_.html> for more information.
        #
        def percolate!(pattern=true)
          @_percolator = pattern
          self
        end

        # A callback method for intercepting percolator matches.
        #
        # Usage:
        #
        #     class Article
        #       # ...
        #       on_percolate do
        #         puts "Article title “#{title}” matches queries: #{matches.inspect}" unless matches.empty?
        #       end
        #     end
        #
        # Based on the response received in `matches`, you may choose to fire notifications,
        # increment counters, send out e-mail alerts, etc.
        #
        def on_percolate(pattern=true,&block)
          percolate!(pattern)
          klass.after_update_elasticsearch_index(block)
        end

        # Returns the status or pattern of percolator for this class.
        #
        def percolator
          @_percolator
        end
      end

      module InstanceMethods

        # Run this document against registered percolator queries, without indexing it.
        #
        # First, register a percolator query:
        #
        #     Article.index.register_percolator_query('fail')    { |query| query.string 'fail' }
        #
        # Then, you may query the percolator endpoint with:
        #
        #     p Article.new(:title => 'This is a FAIL!').percolate
        #
        # Optionally, you may pass a block to filter which percolator queries will be executed.
        #
        # See <http://www.elasticsearch.org/guide/reference/api/percolate.html> for more information.
        def percolate(&block)
          index.percolate instance, block
        end

        # Mark this instance for percolation when adding it to the index.
        #
        def percolate=(pattern)
          @_percolator = pattern
        end

        # Returns the status or pattern of percolator for this instance.
        #
        def percolator
          @_percolator || instance.class.tire.percolator || nil
        end
      end

    end

  end
end
