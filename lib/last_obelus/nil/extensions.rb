module LastObelus
  module Nil
    module Extensions
    	def ellipsis(count=10)
    		''
    	end
	
    	def h_ellipsis(count=10)
    		''
    	end
    end
  end
end

NilClass.class_eval do
  include LastObelus::Nil::Extensions
end
