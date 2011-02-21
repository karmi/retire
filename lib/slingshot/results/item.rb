module Slingshot
  module Results

    class Item < Hash

      # Create new instance, recursively converting all Hashes to Item
      # and leaving everything else alone.
      #
      def initialize(args={})
        # TODO: Need to store underlying Hash in a var and not subclass Hash, since it messes up Hash#default
        if args.is_a? Hash
          args.each_pair do |key, value|
            self[key.to_sym] = value.is_a?(Hash) ? self.class.new(value) : value
          end
          super.replace self
        else
          super
        end
      end

      # Delegate method to a key in underlying hash, if present,
      # otherwise return +nil+.
      #
      def method_missing(method_name, *arguments)
        self.has_key?(method_name.to_sym) ? self[method_name.to_sym] : nil
      end

      def inspect
        s = []; self.each { |k,v| s << "#{k}: #{v.inspect}" }
        %Q|<Item #{s.join(', ')}>|
      end

      alias_method :to_indexed_json, :to_json
    end

  end
end
