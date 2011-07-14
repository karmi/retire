module Tire
  module Results

    class Item
      extend  ActiveModel::Naming
      include ActiveModel::Conversion

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

      def errors
        ActiveModel::Errors.new(self)
      end

      def valid?
        true
      end

      def to_key
        persisted? ? [id] : nil
      end

      def to_hash
        @attributes
      end

      # Let's pretend we're someone else in Rails
      #
      def class
        defined?(::Rails) && @attributes[:_type] ? @attributes[:_type].camelize.constantize : super
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
