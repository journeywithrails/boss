module LastObelus
	module String
	  module Extensions
		
  		def ellipsis(count=10)
  			if(self.length > count)
  				self.to(count-3)+"..."
  			else
  				self
  			end
  		end
		
  		def h_ellipsis(count=10)
  			if(self.length > count)
  				self.to(count-3)+"&hellip;"
  			else
  				self
  			end
  		end

      def identifierize
        downcase.gsub(/\W/, ' ').squeeze.strip.gsub(' ', '_')
      end

      def identifierize!
        replace identifierize
      end

      # not sure what I was using this for, but WE DON'T WANT IT HERE!
      # def to_xml(options={})
      #   xml = options[:builder]
      #   xml.string(self.to_xs, options[:skip_types] ? {} : {:type => "string"})
      # end
      
  	end
	end
end

String.class_eval do
  include LastObelus::String::Extensions
end


