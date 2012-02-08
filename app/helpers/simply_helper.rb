module SimplyHelper

  # draws content in a rounded box for simply accounting integration style
  #
  # options:
  # :label => a label used to identify the box. ids of divs will be constructed from the label
  # :first => if this is true, the outer class will be given a yui class of first, for use in a column layout
  def in_simply_rounded_box(options={}, &block)
    outer_class = 'yui-u'
    outer_class += ' first' if options[:first]
    label = options[:label] || 'simply_box'
    concat(
      content_tag(:div, :class => outer_class, :id => "#{label}_box") do
        options[:caption].blank? ? "" : content_tag(:div, options[:caption], :class => 'caption') +
        simply_rounded_box_opener +        
        content_tag(:div, :class => "white content", :id => "#{label}_content", :style=>options[:content_style]) do
          capture(&block)
        end +
        simply_rounded_box_closer
      end, 
    block.binding)
  end


  
  def simply_rounded_box_opener
    <<-EOQ
		<div class="corner_large_tr" style="clear: both; height: 20px;">
			<div style="height: 20px;" class="corner_large_tl">
				<div class="infobox_empty">
				</div>	
			</div>
		</div>
    EOQ
  end


  def simply_rounded_box_closer
    <<-EOQ
		<div class="tour_box_bl">
			<div class="tour_box_br">	
			</div>
		</div>
    EOQ
  end

end