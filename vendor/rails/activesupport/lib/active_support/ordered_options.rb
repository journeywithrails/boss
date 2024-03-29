# OrderedHash is namespaced to prevent conflicts with other implementations
module ActiveSupport
  # Hash is ordered in Ruby 1.9!
  if RUBY_VERSION >= '1.9'
    OrderedHash = ::Hash
  else
    class OrderedHash < Array #:nodoc:
      def []=(key, value)
        if pair = assoc(key)
          pair.pop
          pair << value
        else
          self << [key, value]
        end
      end

      def [](key)
        pair = assoc(key)
        pair ? pair.last : nil
      end

      def keys
        collect { |key, value| key }
      end

      def has_key?(key)
        !assoc(key).nil?
      end
      
      def values
        collect { |key, value| value }
      end
      
      def delete(key)
        pair = assoc(key)
        super pair
      end
    end
  end
end

class OrderedOptions < ActiveSupport::OrderedHash #:nodoc:
  def []=(key, value)
    super(key.to_sym, value)
  end

  def [](key)
    super(key.to_sym)
  end

  def method_missing(name, *args)
    if name.to_s =~ /(.*)=$/
      self[$1.to_sym] = args.first
    else
      self[name]
    end
  end
end
