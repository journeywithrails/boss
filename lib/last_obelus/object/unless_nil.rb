module LastObelus

	module Object
	  module UnlessNil
      def unless_nil?(dot_path, b=nil, &block)
        if dot_path.nil? || dot_path == ''
          if block_given? and !b.nil?
            return(yield self)
          else
            return self
          end
        end

        messages = dot_path.split('.')
        result = self

        while(!result.nil? && msg = messages.shift) do
          result = result.send(msg)
        end

        return result.unless_nil?(nil,b, &block)
      end
    end
	end

	module NilClass
	  module UnlessNil
      def unless_nil?(dot_path, b)
        if block_given? and !b.nil?
          return(yield b)
        else
          return b
        end
      end
  	end
	end


end

Object.class_eval do
  include LastObelus::Object::UnlessNil
end

NilClass.class_eval do
  include LastObelus::NilClass::UnlessNil
end


