
# A form builder
#
class SageFormBuilder < ActionView::Helpers::FormBuilder
  
  #specify the tooltip anchor image id as :tool_anchor_id=>"ifd"
  #help text as :help_text=>"help me"
  def text_field_with_help_text(method, options={})
    tag_output = text_field(method, options)
    help_text = options[:help_text]
    tool_anchor_id = options[:tool_anchor_id]
    tag_tooltip = @template.image_tag("/images/questionmark.gif", :alt=>"", :id=>options[:tool_anchor_id])
    tag_script =  "<script language=\"JavaScript\">  new YAHOO.widget.Tooltip(\"#{tool_anchor_id}_tip\", { 
      context:\"#{tool_anchor_id}\",preventoverlap:false,fixedcenter:false,
      constraintoviewport:false,
      text:\"#{help_text}\",
      showDelay:500 } ); </script>"
    
    return tag_output + tag_tooltip + tag_script
   end
   
end

  
