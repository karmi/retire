module Tire

  # Represents an *alias* in _Elasticsearch_. An alias may point to one or multiple
  # indices, for instance to separate physical indices into logical entities, where
  # each user has a "virtual index" or for setting up "sliding window" scenarios.
  #
  # See: http://www.elasticsearch.org/guide/reference/api/admin-indices-aliases.html
  #
  class Alias

    # Create an alias pointing to multiple indices:
    #
    #     Tire::Alias.create name: 'my_alias', indices: ['index_1', 'index_2']
    #
    # Pass the routing and/or filtering configuration in the options Hash:
    #
    #     a = Tire::Alias.new name:    'index_anne',
    #                     indices: ['index_2012_04', 'index_2012_03', 'index_2012_02'],
    #                     routing: 1,
    #                     filter:  { :terms => { :user => 'anne' } }
    #     a.save
    #
    # You may configure the alias in an imperative manner:
    #
    #     a = Tire::Alias.new
    #     a.name('index_anne')
    #     a.index('index_2012_04')
    #     a.index('index_2012_03')
    #     # ...
    #     a.save
    #
    # or more declaratively, with a block:
    #
    #     Tire::Alias.new name: 'my_alias' do
    #       index 'index_A'
    #       index 'index_B'
    #       filter :terms, username: 'mary'
    #     end
    #
    # To update an existing alias, find it by name, configure it and save it:
    #
    #     a = Tire::Alias.find('my_alias')
    #     a.indices.delete 'index_A'
    #     a.indices.add    'index_B'
    #     a.indices.add    'index_C'
    #     a.save
    #
    # Or do it with a block:
    #
    #     Tire::Alias.find('articles_aliased') do |a|
    #       a.indices.remove 'articles_2'
    #       puts '---', "#{a.name} says: /me as JSON >", a.as_json, '---'
    #       a.save
    #     end
    #
    # To remove indices from alias, you may want to use the `delete_all` method:
    #
    #
    #     require 'active_support/core_ext/numeric'
    #     require 'active_support/core_ext/date/calculations'
    #
    #     a = Tire::Alias.find('articles_aliased')
    #     a.indices.delete_if do |i|
    #       Time.parse( i.gsub(/articles_/, '') ) < 4.weeks.ago rescue false
    #     end
    #     a.save
    #
    # To get all aliases, use the `Tire::Alias.all` method:
    #
    #     Tire::Alias.all.each do |a|
    #      puts "#{a.name.rjust(30)} points to: #{a.indices}"
    #    end
    #
    def initialize(attributes={}, &block)
      raise ArgumentError, "Please pass a Hash-like object" unless attributes.respond_to?(:each_pair)

      @attributes = { :indices => IndexCollection.new([]) }

      attributes.each_pair do |key, value|
        if ['index','indices'].include? key.to_s
          @attributes[:indices] = IndexCollection.new(value)
        else
          @attributes[key.to_sym] = value
        end
      end

      block.arity < 1 ? instance_eval(&block) : block.call(self) if block_given?
    end

    # Returns a collection of Tire::Alias objects for all aliases defined in the cluster, or for a specific index.
    #
    def self.all(index=nil)
      @response = Configuration.client.get [Configuration.url, index, '_aliases'].compact.join('/')

      aliases = MultiJson.decode(@response.body).inject({}) do |result, (index, value)|
        # 1] Skip indices without aliases
        next result if value['aliases'].empty?

        # 2] Build a reverse map of hashes (alias => indices, config)
        value['aliases'].each do |key, value| (result[key] ||= { 'indices' => [] }).update(value)['indices'].push(index) end
        result
      end

      # 3] Build a collection of Alias objects from hashes
      aliases.map do |key, value|
        self.new(value.update('name' => key))
      end

    ensure
      # FIXME: Extract the `logged` method
      Alias.new.logged '_aliases', %Q|curl "#{Configuration.url}/_aliases"|
    end

    # Returns an alias by name
    #
    def self.find(name, &block)
      a = all.select { |a| a.name == name }.first
      block.call(a) if block_given?
      return a
    end

    # Create new alias
    #
    def self.create(attributes={}, &block)
      new(attributes, &block).save
    end

    # Delegate to the `@attributes` Hash
    #
    def method_missing(method_name, *arguments)
      @attributes.has_key?(method_name.to_sym) ? @attributes[method_name.to_sym] : super
    end

    # Get or set the alias name
    #
    def name(value=nil)
      value ? (@attributes[:name] = value and return self) : @attributes[:name]
    end

    # Get or set the alias indices
    #
    def indices(*names)
      names = Array(names).flatten
      names.compact.empty? ? @attributes[:indices] : (names.each { |n| @attributes[:indices].push(n) } and return self)
    end
    alias_method :index, :indices

    # Get or set the alias routing
    #
    def routing(value=nil)
      value ? (@attributes[:routing] = value and return self) : @attributes[:routing]
    end

    # Get or set the alias routing
    def filter(type=nil, *options)
      type ? (@attributes[:filter] = Search::Filter.new(type, *options).to_hash and return self ) : @attributes[:filter]
    end

    # Save the alias in _Elasticsearch_
    #
    def save
      @response = Configuration.client.post "#{Configuration.url}/_aliases", to_json

    ensure
      logged '_aliases', %Q|curl -X POST "#{Configuration.url}/_aliases" -d '#{to_json}'|
    end

    # Return a Hash suitable for JSON serialization
    #
    def as_json(options=nil)
      actions = []
      indices.add_indices.each do |index|
        operation = { :index => index, :alias => name }
        operation.update( { :routing => routing } ) if respond_to?(:routing) and routing
        operation.update( { :filter  => filter } )  if respond_to?(:filter)  and filter
        actions.push( { :add => operation } )
      end

      indices.remove_indices.each do |index|
        operation = { :index => index, :alias => name }
        actions.push( { :remove => operation } )
      end

      { :actions => actions }
    end

    # Return alias serialized in JSON for _Elasticsearch_
    #
    def to_json(options=nil)
      as_json.to_json
    end

    def inspect
      %Q|<#{self.class} #{@attributes.inspect}>|
    end

    def to_s
      name
    end

    def logged(endpoint='/', curl='')
      # FIXME: Extract the `logged` method into module and mix it into classes
      if Configuration.logger
        error = $!

        Configuration.logger.log_request endpoint, @name, curl

        code = @response ? @response.code : error.class rescue 200

        if Configuration.logger.level.to_s == 'debug'
          body = if @response
            MultiJson.encode(@response.body, :pretty => Configuration.pretty)
          else
            error.message rescue ''
          end
        else
          body = ''
        end

        Configuration.logger.log_response code, nil, body
      end
    end

    # Thin wrapper around array representing a collection of indices for a specific alias,
    # which allows hooking into adding/removing indices.
    #
    # It keeps track of which aliases to add and which to remove in two separate collections,
    # `add_indices` and `remove_indices`.
    #
    # It delegates Enumerable-like methods to the `add_indices` collection.
    #
    class IndexCollection
      include Enumerable
      attr_reader :add_indices, :remove_indices

      def initialize(*values)
        @add_indices    = Array.new(values).flatten.compact
        @remove_indices = []
      end

      def push(value)
        @add_indices |= [value]
        @remove_indices.delete value
      end
      alias_method :add, :push

      def delete(value)
        @add_indices.delete value
        @remove_indices |= [value]
      end
      alias_method :remove, :delete

      def delete_if(&block)
        @add_indices.clone.each do |name|
          delete(name) if block.call(name)
        end
      end

      def each(&block)
        @add_indices.each(&block)
      end

      def empty?
        @add_indices.empty?
      end

      def clear
        @remove_indices = @add_indices.clone
        @add_indices.clear
      end

      def [](index)
        @add_indices[index]
      end

      def size
        @add_indices.size
      end

      def to_ary
        @add_indices
      end

      def to_s
        @add_indices.join(', ')
      end

      def inspect
        %Q|<#{self.class} #{@add_indices.map{|i| "\"#{i}\""}.join(', ')}>|
      end

    end

  end

end
