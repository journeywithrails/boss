
# A form builder that uses css to produce tableless, lined-up forms.
#
class CssFormBuilder < ActionView::Helpers::FormBuilder
  
   (field_helpers - %w(hidden_field)).each do |selector|
    src = <<-END_SRC
      def #{selector}(field, options = {})
        process(field,options,super(field,options.purge_custom_tags))
      end
    END_SRC
    class_eval src, __FILE__, __LINE__
  end
  
  def select(field,choises,options={},html_options={})
    process(field,html_options,super(field,choises,options,html_options.purge_custom_tags))
  end
  
  def date_select(field,options={})
    process(field,options,super(field,options.purge_custom_tags))
  end
  
  def radio_button(field,tag_value,options={})
    process(field,options,super(field,tag_value,options.purge_custom_tags))
  end
  
  def select_with_choises(field, select_choices, options = {}, html_options = {})
    process(field,html_options,super(field,select_choices,options,html_options.purge_custom_tags))
  end
  
  private
  
  def process(field,options,tag_output)
    unless (extra=options[:extra]).nil?
      tag_extra="<span style='float:left'>#{extra}</span>"
    else
      tag_extra=""
    end if
    label=""#options[:label] ||= (field.to_s.humanize).translate
    @template.content_tag("label", tag_output + tag_extra)
  end
  
end

# Wrap form_for, using CssFormBuilder
#
def css_form_for(name, object = nil, options = {}, &proc)
  form_for(name, object, options.merge({:html=>{:class=>'cssform'},:builder => CssFormBuilder}), &proc)
end

# Wrap remote_form_for, using CssFormBuilder
#
def remote_css_form_for(name, object = nil, options = {}, &proc)
  options[:html]||=Hash.new
  options[:html].merge!({:class => 'cssform'})
  remote_form_for(name, object, options.merge({:builder => CssFormBuilder}), &proc)
end

# Wrap fields_for, using CssFormBuilder
#
def css_fields_for(object_name, *args, &proc)
  #fields_for(object_name, object, options.merge({:html=>{:class=>'cssform'},:builder => CssFormBuilder}), &proc)
  raise ArgumentError, "Missing block" unless block_given?
  options = args.last.is_a?(Hash) ? args.pop : {}
  object  = args.first
  yield((options[:builder] || CssFormBuilder).new(object_name, object, self, options, proc))
end
