module ReportsHelper
  def report_filter_caption
    caption = "<div id='caption'>"
    unless @filters.fromdate.blank? and @filters.todate.blank? and @filters.customers.blank?      
       # RADAR fix for translation, won't work with non-European languages http://sage.svnrepository.com/sage/trac.cgi/ticket/13333
       caption += _("Showing reports ")
       unless @filters.customers.blank?
         caption += _(" for ") + pluralize(@filters.customers.length, _("customer")) + ":"
         caption += " <span id='customers'>"
         @filters.customers.each do |c|
           customer = Customer.find(c)
           caption += "#{customer.name}, "
         end
         caption.chomp!(", ")
         caption += "</span>"
       end
       
       unless @filters.fromdate.blank? or @filters.todate.blank?
         caption += "; "
       end
       unless @filters.fromdate.blank?
         caption += _(" from ") + "<span id='from_date'>#{@filters.fromdate}</span>"
       end
       unless @filters.todate.blank?
         caption += _(" until ") + "<span id='to_date'>#{@filters.todate}</span>"
       end
       caption += "."
       caption += "<br/><br/>"

     end
     caption += "</div>"
     return caption
  end
  
  def invoice_report_link(link_text=_("Invoice Report"))
    if bookkeeper_view?
      link_to link_text, bookkeeping_client_report_path(@client.id, :invoice)
    else
      link_to link_text, report_path(:invoice)
    end
  end

  def bookkeeper_view?
    current_user.profile.current_view == :bookkeeper
  end
  
  def payment_report_link(link_text=_("Payment Report"))
    if bookkeeper_view?
      link_to link_text, bookkeeping_client_report_path(@client.id, :payment)
    else
      link_to link_text, report_path(:payment)
    end  	
  end
end
