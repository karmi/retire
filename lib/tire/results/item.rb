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
          if value.is_a?(Array)
            @attributes[key.to_sym] = value.map { |item| @attributes[key.to_sym] = item.is_a?(Hash) ? Item.new(item.to_hash) : item }
          else
            @attributes[key.to_sym] = value.is_a?(Hash) ? Item.new(value.to_hash) : value
          end
        end
      end

      # Delegate method to a key in underlying hash, if present,
      # otherwise return +nil+.
      #
      def method_missing(method_name, *arguments)
        @attributes.has_key?(method_name.to_sym) ? @attributes[method_name.to_sym] : nil
      end

      def [](key)
        @attributes[key.to_sym]
      end

      def id
        @attributes[:_id]   || @attributes[:id]
      end

      def type
        @attributes[:_type] || @attributes[:type]
      end

      def persisted?
        !!id
      end

      def to_key
        persisted? ? [id] : nil
      end

      def to_hash
        @attributes
      end

      def inspect
        s = []; @attributes.each { |k,v| s << "#{k}: #{v.inspect}" }
        %Q|<Item#{self.class.to_s == 'Tire::Results::Item' ? '' : " (#{self.class})"} #{s.join(', ')}>|
      end

      def to_json(options=nil)
        @attributes.to_json(options)
      end
      alias_method :to_indexed_json, :to_json

    end

  end
end
