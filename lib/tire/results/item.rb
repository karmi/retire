module Tire
  module Results

    class Item

      # Create new instance, recursively converting all Hashes to Item
      # and leaving everything else alone.
      #
      def initialize(args={})
        raise ArgumentError, "Please pass a Hash-like object" unless args.respond_to?(:each_pair)
        @attributes = {}
        args.each_pair do |key, value|
          @attributes[key.to_sym] = value.is_a?(Hash) ? self.class.new(value.to_hash) : value
        end
      end

      # Delegate method to a key in underlying hash, if present,
      # otherwise return +nil+.
      #
      def method_missing(method_name, *arguments)
        @attributes.has_key?(method_name.to_sym) ? @attributes[method_name.to_sym] : nil
      end

      def [](key)
        @attributes[key]
      end

      def id
        @attributes[:_id] || @attributes[:id]
      end

      def persisted?
        !!id
      end

      def inspect
        s = []; @attributes.each { |k,v| s << "#{k}: #{v.inspect}" }
        %Q|<Item #{s.join(', ')}>|
      end

      def to_json(options={})
        @attributes.to_json(options)
      end
      alias_method :to_indexed_json, :to_json

    end

  end
end
