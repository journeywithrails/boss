class CalendarDateSelect
  FORMATS = {
    :natural => {
      :date => "%B %d, %Y",
      :time => " %I:%M %p"
    },
    :hyphen_ampm => {
      :date => "%Y-%m-%d",
      :time => " %I:%M %p",
      :javascript_include => "calendar_date_select_format_hyphen_ampm"
    },
    :american => {
      :date => "%m/%d/%Y",
      :time => " %I:%M %p",
      :javascript_include => "calendar_date_select_format_american"
    },
    :euro_24hr => {
      :date => "%d %B %Y", 
      :time => " %H:%M",
      :javascript_include => "calendar_date_select_format_euro_24hr"
    }
  }
  
  cattr_accessor :image
  @@image = "calendar.gif"
  
  cattr_reader :format
  @@format = FORMATS[:natural]
  
  class << self
    def format=(format)
      raise "CalendarDateSelect: Unrecognized format specification: #{format}" unless FORMATS.has_key?(format)
      @@format = FORMATS[format]
    end
    
    def javascript_format_include
      @@format[:javascript_include]
    end
    
    def date_format_string(time=false)
      @@format[:date] + ( time ? @@format[:time] : "" )
    end
  end
  
  module FormHelper
    def calendar_date_select_tag( name, value = nil, options = {})
      image_options = options.delete(:image_options) || {}
      calendar_options = calendar_date_select_process_options(options)
      value = (value.strftime(calendar_options[:format]) rescue value) if (value.respond_to?("strftime"))
      
      calendar_options.delete(:format)
      
      options[:id] ||= name
      tag = calendar_options[:embedded] ? 
        hidden_field_tag(name, value, options) :
        text_field_tag(name, value, options)
      
      calendar_date_select_output(tag, calendar_options, image_options)
    end
    
    def calendar_date_select_process_options(options)
      calendar_options = {}
      # goddamn newbies who make an options system that doesn't pass through new options so 
      # that I have to trace through the code and find where I need to explicitly add them.
      # I don't have time to refactor it to delete unwanted options instead. Or to just
      # take two options params, one for html & one for js calendar object
      calendar_options[:horiz_offset] = options[:horiz_offset] unless options[:horiz_offset].blank?;
      calendar_options[:vert_offset] = options[:vert_offset] unless options[:vert_offset].blank?;
      
      callbacks = [:before_show, :before_close, :after_show, :after_close, :after_navigate]
      for key in [:time, :embedded, :buttons, :format, :year_range] + callbacks
        calendar_options[key] = options.delete(key) if options.has_key?(key)
      end
      
      # surround any callbacks with a function, if not already done so
      for key in callbacks
        calendar_options[key] = "function(param) { #{calendar_options[key]} }" unless calendar_options[key].include?("function") if calendar_options[key]
      end
    
      calendar_options[:year_range] ||= 10
      calendar_options[:format] ||= CalendarDateSelect.date_format_string(calendar_options[:time])
      
      calendar_options
    end
    
    def calendar_date_select(object, method, options={})
      obj = instance_eval("@#{object}") || options[:object]
      
      image_options = options.delete(:image_options) || {}
      image_options[:alt] ||= object.to_s.titleize + " " + method.to_s.titleize
      if !options.include?(:time) && obj.class.respond_to?("columns_hash")
        column_type = (obj.class.columns_hash[method.to_s].type rescue nil)
        options[:time] = true if column_type==:datetime
      end
      
      calendar_options = calendar_date_select_process_options(options)
      calendar_options[:has_error] = (obj.respond_to?("errors") && obj.errors.respond_to?("on") && obj.errors.on(method))
      
      value = obj.send(method).strftime(calendar_options[:format]) rescue obj.send("#{method}_before_type_cast")

      calendar_options.delete(:format)
      options = options.merge(:value => value)

      tag = ActionView::Helpers::InstanceTag.new(object, method, self, nil, options.delete(:object))
      calendar_date_select_output(
        tag.to_input_field_tag(calendar_options[:embedded] ? "hidden" : "text", options), 
        calendar_options,
        image_options
      )
    end  
    
    def calendar_date_select_output(input, calendar_options = {}, image_options = {})
      out = input
      has_error = calendar_options.delete(:has_error)
      input_selector = has_error ? "previous().down('input')" : 'previous()'
      if calendar_options[:embedded]
        uniq_id = "cds_placeholder_#{(rand*100000).to_i}"
        # we need to be able to locate the target input element, so lets stick an invisible span tag here we can easily locate
        out << content_tag(:span, nil, :style => "display: none; position: absolute;", :id => uniq_id)
        out << javascript_tag("new CalendarDateSelect( $('#{uniq_id}').#{input_selector}, #{options_for_javascript(calendar_options)} ); ")
      else
        out << " "
        image_options[:onclick] = "new CalendarDateSelect( $(this).#{input_selector}, #{options_for_javascript(calendar_options)} );"
        image_options[:style] ||= 'border:0px; cursor:pointer; vertical-align:bottom;'
        
        out << image_tag(CalendarDateSelect.image, 
            image_options)
      end
      
      out
    end
  end
end


module ActionView
  module Helpers
    class FormBuilder
      def calendar_date_select(method, options = {})
        @template.calendar_date_select(@object_name, method, options.merge(:object => @object))
      end
    end
  end
end
