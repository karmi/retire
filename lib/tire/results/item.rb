module Tire
  module Results

    class Item < Hash

      # Create new instance, recursively converting all Hashes to Item
      # and leaving everything else alone.
      #
      def initialize(args={})
        raise ArgumentError, "Please pass a Hash-like object" unless args.respond_to?(:each_pair)
        args.each_pair do |key, value|
          self[key.to_sym] = value.is_a?(Hash) ? self.class.new(value.to_hash) : value
        end
      end

      # Delegate method to a key in underlying hash, if present,
      # otherwise return +nil+.
      #
      def method_missing(method_name, *arguments)
        self.has_key?(method_name.to_sym) ? self[method_name.to_sym] : nil
      end

      # Get ID
      #
      def id
        self[:id]
      end

      def persisted?
        !!id
      end

      def inspect
        s = []; self.each { |k,v| s << "#{k}: #{v.inspect}" }
        %Q|<Item #{s.join(', ')}>|
      end

      alias_method :to_indexed_json, :to_json

    end

  end
end
