module LastObelus
  module ActionView
    module FallbackFormats

      def self.included(base)
        base.extend(ClassMethods)
        
        base.class_eval do
          alias_method_chain :find_template_extension_from_handler, :fallback_formats
        end
      end

      module ClassMethods
        def fallback_formats
          @@fallback_formats ||= {}
        end
        
        def register_fallback_format(format, *fallback)
          @@fallback_formats ||= {}
          @@fallback_formats[format.to_sym] ||= fallback.flatten
        end
      end


      def find_template_extension_from_handler_with_fallback_formats(template_path, formatted = nil)
        if formatted 
          formats = [template_format]
          formats += ::ActionView::Base.fallback_formats[template_format] unless ::ActionView::Base.fallback_formats[template_format].nil?
        else
          formats = [nil]
        end
        
        formats.each do |format|
        
          checked_template_path = format ? "#{template_path}.#{format}" : template_path

          self.class.template_handler_extensions.each do |extension|
            if template_exists?(checked_template_path, extension)
              return format ? "#{format}.#{extension}" : extension.to_s
            end
          end
        end
        nil
      end
      
    end
  end
end

ActionView::Base.send(:include, LastObelus::ActionView::FallbackFormats)