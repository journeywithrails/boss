if %w{production staging}.include?(ENV["RAILS_ENV"])
module ActionView
  module Helpers
        module AssetTagHelper
          #save the old method
          alias path_to_javascript_old path_to_javascript         
          alias path_to_stylesheet_old path_to_stylesheet
          
          def path_to_javascript(source)
            
            s = path_to_javascript_old(source)

              if (s.include?('/javascripts'))
                s = s.sub("/javascripts", "/javascripts/build")
              end             
            s
          end
          
          def path_to_stylesheet(source)
            
            s = path_to_stylesheet_old(source)
              if (s.include?('/stylesheets'))
                s = s.sub("/stylesheets", "/stylesheets/build")
              end             
            s
          end          
        end
  end
end

end

  
module ActionView
  module Helpers
    module ActiveRecordHelper      
      def error_messages_for(*params)
        options = params.extract_options!.symbolize_keys
        if object = options.delete(:object)
          objects = [object].flatten
        else
          objects = params.collect {|object_name| instance_variable_get("@#{object_name}") }.compact
        end
        count   = objects.inject(0) {|sum, object| sum + object.errors.count }
        unless count.zero?
          if options[:partial] 
            render :partial => options[:partial], 
            :locals => {:errors => error_messages} 
          else 
            html = {}
            [:id, :class].each do |key|
              if options.include?(key)
                value = options[key]
                html[key] = value unless value.blank?
              else
                html[key] = 'errorExplanation'
              end
            end
          if html[:class] == "errorExplanation" and request.xhr?
            html[:class] = "ExtError"
          end
            options[:object_name] ||= params.first
            options[:header_message] = "#{pluralize(count, 'error')} prohibited this #{options[:object_name].to_s.gsub('_', ' ')} from being saved" unless options.include?(:header_message)
            error_messages = objects.sum {|object| object.errors.full_messages.map {|msg| content_tag(:li, msg) } }.join

            contents = ''
            contents << content_tag(options[:header_tag] || :h2, options[:header_message]) unless options[:header_message].blank?
            contents << content_tag(:ul, error_messages)

            content_tag(:div, contents, html)
          end
        else
          ''
        end
      end #def error_messages_for 
    end
  end
end

  