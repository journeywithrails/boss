module LastObelus
  module Hash
    module Extensions
      def deep_merge(second, opts={})
        # From: http://www.ruby-forum.com/topic/142809
        # Author: Stefan Rusterholz
        # mj: added the coerce_to_hash option to work with deep structures that have ostructs on the leaves
        # RADAR: if the other module LastObelus::Hash::Extensions is going to be loaded first, have to use ::Hash here not just Hash
        if opts[:coerce_to_hash]          
          merger = proc { |key,v1,v2| v1 = v1.to_h if v1.respond_to?(:to_h); v2 = v2.to_h if v2.respond_to?(:to_h); ::Hash === v1 && ::Hash === v2 ? v1.merge(v2, &merger) : v2 }
        else
          merger = proc { |key,v1,v2| ::Hash === v1 && ::Hash === v2 ? v1.merge(v2, &merger) : v2 }
        end
        self.merge(second, &merger)
      end
      
      def deep_merge!(second)
        # From: http://www.ruby-forum.com/topic/142809
        # Author: Stefan Rusterholz
        if opts[:coerce_to_hash]          
          merger = proc { |key,v1,v2| v1 = v1.to_h if v1.respond_to?(:to_h); v2 = v2.to_h if v2.respond_to?(:to_h); ::Hash === v1 && ::Hash === v2 ? v1.merge!(v2, &merger) : v2 }
        else
          merger = proc { |key,v1,v2| ::Hash === v1 && ::Hash === v2 ? v1.merge!(v2, &merger) : v2 }
        end
        self.merge!(second, &merger)
      end
      
      def deep_key_exists?(*keys)
        return false unless keys
        h=self
        keys.each do |k|
          return false unless h.has_key?k
          h=h[k]
        end
        return true
      end
      
      def deep_value(*keys)
        return nil unless keys
        h=self
        keys.each do |k|
          return nil unless h.has_key?k
          h=h[k]
        end
        h
      end
    end
  end
end

::Hash.class_eval do
  include LastObelus::Hash::Extensions
end