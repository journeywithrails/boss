# RADAR: scope -- have to use ::OpenStruct here not just OpenStruct, because otherwise is_a etc. will think you mean LastObelus::OpenStruct

module LastObelus
  module OpenStruct
    module Extensions
      def to_h
        @table
      end
      
      def to_json(options)
      end
      
      def [](key)
        key = key.to_sym unless key.is_a?(Symbol)
        @table[key]
      end

      def []=(key,val)
        raise TypeError, "can't modify frozen #{self.class}", caller(1) if self.frozen?
        key = key.to_sym unless key.is_a?(Symbol)
        @table[key]=val
      end
      
      def deep_merge!(other)
        raise TypeError, "can't modify frozen #{self.class}", caller(1) if self.frozen?
        @table.each do |k, v|
          if v.is_a?(::OpenStruct)
            if other[k].is_a?(::OpenStruct)
              v.deep_merge!(other[k])
            elsif !other[k].nil?
              raise TypeError, "can't merge scalar for #{k} into OpenStruct", caller(1)
            end
          elsif !other[k].nil?
            self[k] = other[k]
          end
        end
        self
      end


    end
  end
end

OpenStruct.class_eval do
  include LastObelus::OpenStruct::Extensions
end