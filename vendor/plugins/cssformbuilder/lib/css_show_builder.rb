

module ActionView
  module Helpers
    class ShowBuilder #:nodoc:
      # The methods which wrap a form helper call.
      class_inheritable_accessor :field_helpers
      self.field_helpers = (FormHelper.instance_methods - ['form_for'])
      
      attr_accessor :object_name, :object
      
      def initialize(object_name, object, template, options, proc)
        @object_name, @object, @template, @options, @proc = object_name, object, template, options, proc        
      end
      
      def radio_button(method, tag_value, options = {})
        @template.radio_button(@object_name, method, tag_value, options.merge(:object => @object))
      end
    end
  end
end

# A builder, like CssFormBuilder, that, instead of generating a form. display field values, using
# the same look as CssFormBuilder
#
class CssShowBuilder <  ActionView::Helpers::ShowBuilder
  
   (field_helpers - %w(radio_button hidden_field)).each do |selector|
    src = <<-END_SRC
      def #{selector}(field, options = {})
         process(field,options,@object.send(field).to_s)
      end
    END_SRC
    class_eval src, __FILE__, __LINE__
  end
  
  def select(field,choises,options={},html_options={})
    process(field,html_options,find_selected_value(@object.send(field),choises).to_s)
  end
  
  def check_box(field,options={})
    options[:class]='checkbox'
    process(field,options.purge_custom_tags,@object.send(field).to_s)
  end
  
  def hidden_field(field, options = {})
  end
  
  def text_area(field, options = {})
    text=@object.send(field).to_s
    options[:class]='textarea'
    process(field,options.purge_custom_tags,'<pre>' + text+ '</pre>')
  end
  
  def radio_button(field,tag_value,options={})
    options[:class]='radiobutton'
    text=@object.send(field).to_s==tag_value.to_s ?  'X' : ' ' 
    process(field,options,text)
  end
  
  def select_with_choises(field, select_choices, options = {}, html_options = {})
    text=find_selected_choise(@object.send(field),select_choices).to_s
    process(field,html_options,text)
  end
  
  def date_select(field,options={})
    process(field,options,@object.send(field).to_s)
  end
    
  private
  
  def process(field,options,tag_output)
    class_hash={:class=>options[:class]}
    tag_output = '&nbsp;' + tag_output unless  options[:class]=='textarea'
    output=@template.content_tag('span', tag_output,class_hash)
    label=options[:label] ||= (field.to_s.humanize).translate
    @template.content_tag("label", label + ":" + output)
  end
  
  def find_selected_value(selected,choices)
    return if selected.nil?
    choices.each do |elem|
      return elem.first if elem.respond_to?("last") && elem.last==selected
      return elem if elem==selected
    end 
    ""
  end
  
  def find_selected_choise(selected,choises)
    res=''
    selected_to_s=selected.to_s
    #note: key group skips ' and " char in order to avoid selected="selected is appended to key group
    choises.gsub(/<option\ value=[\"|\']([^\'|^\"]*)[\"|\'].*>(.*)<\/option>/){|s1| res=$2 if $1.to_s==selected_to_s}
    res
  end
end

# Like css_form_for, but generates a html output that display field values
#
def css_show_for(name, object = nil, options = {}, &proc)
  show_for(name, object, options.merge({:html=>{:class=>'cssform'},:builder => CssShowBuilder}), &proc)
end

def remote_css_show_for(name, object = nil, options = {}, &proc)
  show_for(name, object, options.merge({:html=>{:class=>'cssform'},:builder => CssShowBuilder}), &proc)
end

private

def show_for(object_name, *args, &proc)
  raise ArgumentError, "Missing block" unless block_given?
  options = args.last.is_a?(Hash) ? args.pop : {}
  concat("<div class='css_show'>", proc.binding)
  show_fields_for(object_name, *(args << options), &proc)
  concat('</div>', proc.binding)
end

def show_fields_for(object_name, *args, &proc)
  raise ArgumentError, "Missing block" unless block_given?
  options = args.last.is_a?(Hash) ? args.pop : {}
  object  = args.first
  yield((options[:builder] || ActionView::Helpers::ShowBuilder).new(object_name, object, self, options, proc))
end
