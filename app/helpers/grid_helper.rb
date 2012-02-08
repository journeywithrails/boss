module GridHelper

  def grid_body dom_id, title, elements, cols=[]
    grid_wrapper title, dom_id do
       grid_content(elements, cols) 
    end
  end

  def grid_wrapper title, dom_id, &block
    content_tag "div", :class=>"grid-panel" do
      content_tag("div", title, :class=>"header") +
      content_tag("div", :class=>"wrapper", :id=>dom_id) do
        block.call
      end
    end
  end

  def grid_content elements, cols
    content_tag "div", :class => "grid-content" do
      content_tag "table", :id=>"recurring-grid" do
        render_header_row(cols) + render_body_rows(elements, cols)
      end
    end
  end

  def render_header_row cols
    content_tag "tr", :class => "row names" do
      center = ""
      cols.each do |col|
        center += content_tag("td","<span>#{col[:field]}</span>",:class=>col[:class])
      end
      center
    end
  end

  def render_body_rows elements, cols
    content_rows = ""
    elements.each do |el|
      content_rows += render_row(el,cols, :row_class=>"row normal invoice", :row_id=>"invoice_#{el.id}")
    end
    content_rows
  end

  def render_row el, cols, options={}
    content_tag "tr", :class => options[:row_class], :id => options[:row_id] do
      content = ""
      cols.each do |col|
         content += content_tag("td","<div class='#{col[:field]}'>#{col[:data].call el}</div>",:class=>col[:class])
      end
      content
    end
  end

end
