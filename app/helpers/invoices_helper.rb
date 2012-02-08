module InvoicesHelper

  # with this trick you can do:
  #   InvoicesHelper.invoice_was_successfully_updated
  extend self;

  def recurring_schedule_description(invoice)
    case invoice.schedule.frequency.to_s
      when "monthly": _("each month")
      when "yearly": _("each year")
      when "weekly": _("every week")
    end
  end

  def toggle_access_link(ak_id, status)
    status ? name = _("Disable access") : name = _("Enable access")
    return (link_to name, toggle_access_path(ak_id))
  end
  
  def clear_line_item_errors(invoice)
  	if invoice.errors["line_items"]
  	  return invoice.errors["line_items"].clear
  	else
      return invoice
  	end
  end
  
  def activity_description(activity)
    case activity.body
    when "sent"
      return _("Sent by email to %{recipients}") % {:recipients => activity.extra}
    when "viewed"
      return _("Viewed online by %{ip}") % {:ip => Socket.gethostbyname(activity.extra)[0,2]} #  resolve IP
    when "updated"
      return _("Updated")
    when "created"
      return _("Created")
    when "bounced"
      return _("Emailed invoice bounced")
    when "payment_applied"
      return _("Payment applied") + " #{format_amount_in_extra(activity.extra)}"
    when "payment_edited"
      return _("Payment edited") + " #{format_amount_in_extra(activity.extra)}"
    when "payment_deleted"
      return _("Payment deleted") + " #{format_amount_in_extra(activity.extra)}"
    when "forward"
      return _("Forwarded to sender")
    else
      return _("unknown activity")
    end
  end

  def format_amount_in_extra(extra_string)
    split_array = extra_string.split(' ')
    return split_array[0] + ' ' + format_amount(split_array[1]) + ' ' + split_array[2]
  end
  
  def add_line_item_link(name, *properties)
    out = link_to_function name, *properties do |page|
      if is_mobile?
        page.insert_html :bottom, :line_items_list, :partial => '/invoices/mobile/line_item', :object => LineItem.new, :locals => {:row_id => 'new_line_item'}
        page << 'Sage.add_new_mobile_line_item();'
      else
        page.insert_html :bottom, :line_items_list, :partial => 'invoices/line_item', :object => LineItem.new, :locals => {:row_id => 'new_line_item'}
        page << 'Sage.add_new_line_item();'
      end

    end
    out
  end
  def show_if_tax_enabled(invoice, tax_key, style=nil)

    if !invoice.send("#{tax_key}_enabled")
      return "display: none"
    else
      return "display: table-cell"
    end
  end
  
  def invoice_status_marker(invoice)
    s=invoice.status
    "<div title=\"#{s}\" class=\"state #{s}\"> </div>"
  end
  
  def send_button_text_for_status(invoice)
    ( invoice.draft? or invoice.printed? or invoice.quote_draft? ) ? _("Send") : _("Re-send")
  end
  
  def is_logo_missing(logo)
    return "missing_image.gif" unless logo && logo.image?
    logo.public_filename
  end
  
  def get_logo_class(logo_url)
    if logo && logo.image?
      return "logo"
    else
      #hiddenprintimage is defined in print.css
      return "logo hiddenprintimage"
    end
  end

    #removing obsolete method
  
  # helper for ordering discount before tax block
  def show_first_if(condition, maybe_first)
    if condition
      maybe_first.call
      yield
    else
      yield
      maybe_first.call
    end
  end  

  def invoice_status(invoice)
    out = <<-EOQ
    <div class="invoice_state" id="#{invoice_status_html_id(invoice)}"><span class="#{invoice.status}">#{invoice.meta_status_string}</span></div>
    EOQ
  end
  
  def invoice_status_html_id(invoice)
    "invoice-#{invoice.to_param}-state"
  end
  
  def taken_auto(invoice)
    @wanted_auto = invoice.wanted_auto
    @available_auto = invoice.available_auto
    if !@wanted_auto.nil? and !@available_auto.nil? and @wanted_auto.integer? and @available_auto.integer?
      i_(@invoice,"<p>Wanted invoice number <b><span id='wanted_auto' value='%{wanted}'>%{wanted}</span></b> has already been taken.<br/>Closest available invoice number: <b><span id='available_auto' value='%{available}'>%{available}</span></b><br/>Use this number instead?</p>") % { :wanted => @wanted_auto, :available => @available_auto }
    else
      ""
    end
  end
  
  def discount_div(invoice)
    if (invoice.discount_amount.class == Fixnum or invoice.discount_amount.class == BigDecimal) and invoice.discount_amount != 0
      if is_mobile?
        "<li><h3>" + _("Discount") + "</h3><span id='invoice_discount_amount'> #{format_amount(invoice.discount_amount)}</span> #{invoice.currency}</li>"     
      else
        "<tr><td class='preview_footer_summary_label'><span>" + _("Discount:") + "</span></td><td class='preview_footer_summary_amount'><span id='invoice_discount_amount'> #{format_amount(invoice.discount_amount)}</span></td></tr>"     
      end
    else
      ""
    end
  end
  
  def can_send_icon(invoice)
    if !invoice.sendable?
      "<font style='color:red;'>" + _("Can't") +" </font>"
    else
      ""
    end
  end
  
  def can_pay_icon(invoice)
    if !invoice.sent?
      "<font style='color:red;'>" + _("Can't") +" </font>"
    else
      ""
    end
  end
  
  def invoice_amount_owing(invoice)
    if !invoice.blank? and !invoice.amount_owing.blank? and (invoice.amount_owing > 0)
      format_amount(invoice.amount_owing)
    else
      "0.00"
    end
  end
  
  def delete_warn_string(invoice)
    if invoice.pay_applications.size > 0
      _("Are you sure you want to delete this invoice? Doing so will permanently erase all recorded payments for this invoice as well!")
    else
      _("Are you sure you want to delete this invoice?")
    end
  end
  
  def placeholder_break(profile)
    size = 0
    size+=1 if !@profile.contact_name.blank?
    size+=1 if !@profile.company_name.blank?
    size+=1 if !@profile.company_address1.blank?
    size+=1 if !@profile.company_address2.blank?
    size+=1 if !@profile.company_city.blank? || @profile.company_state.blank?
    size+=1 if !@profile.company_postalcode.blank? || @profile.company_country.blank?
    size+=1 if !@profile.company_phone.blank? || @profile.company_fax.blank?
    size+=1 if !@profile.website.blank?
    
    return "<br/>" * (8-size)
  end
  
  def no_customer_warning(invoice)
    str = "<br/>"
    str += "<span class='mandatory'>* </span>"
    str += i_(invoice,"Invoices without a customer cannot be sent.")
    str += "<br/>" 
    str += "<span class='mandatory' style='color: white'>* </span>"
    str += _("Please add or select a customer.")
    str
  end
  
  def no_line_item_warning( invoice )
    str = ""
    str += "<span class='mandatory'>* </span>"
    str += i_(invoice,"Invoices must have at least one line item with positive price and quantity before they can be sent.")
    str
  end

  def calculating_totals_string
    str = _("Calculating... %{img}") % {:img => "<img src='/images/loading-medium.gif'>"}
    str
  end
  
  def is_loading_string
    str = _("Loading... %{img}") % {:img => "<img src='/images/loading.gif'>"}
    str
  end
  
  def processing_string
    str = _("Processing... %{img}") % {:img => "<img src='/images/loading.gif'>"}
    str
  end
  
  def updating_string
    str = _("Updating... %{img}") % {:img => "<img src='/images/loading.gif'>"}
    str
  end
  
  def status_action_js
    str = ""
    str += "if ($('flash') != null) {$('flash').remove()};"
    str += "($('#{invoice_status_html_id(@invoice)}').innerHTML = \""
    str += "#{@invoice.meta_status_string}<br/><div class='invoice_status_notice_matched_to_flash'>"
    str += "#{processing_string}"
    str += "</div>\")"
    str
  end

  def choose_payment_types_list(invoice, param_prefix)
    invoice.all_payment_types.map do |payment_type|
      <<-HTML
      <li>
        <label class="normal">
          #{ check_box_tag((param_prefix + '[payment_types][]'), payment_type, invoice.selected_payment_type?(payment_type), :id => ('pay_by_' + payment_type.to_s)) }
          #{ _(TornadoGateway.payment_type_name(payment_type)) }
        </label>
      </li>
      HTML
    end.join("\n\t")
  end

  def get_template_list_name
    {  "default" =>  _("Professional 1"),
       "prof1" => _("Professional 2"),
       "service1" => _("Service"),
       "bold_orange" => _("Bold Orange"),
       "trendy_blue" => _("Clean Blue"),
       "power_red" => _("Power Red")}
  end

  def get_invoice_template(invoice, selected_template=nil)
    template_list = get_template_list_name()
    #check if selected_template is a valid template
    if (!selected_template.nil? && template_list.keys.include?(selected_template))
      invoice.template_name = selected_template
    end
    if invoice.template_name.nil? or invoice.template_name.blank? or !template_list.keys.include?(invoice.template_name)
      'default'
    else
      invoice.template_name
    end
  end

#  def invoice_number(invoice) ( invoice.quote? ?
#      _("Quote %{num}") :
#      _("Invoice %{num}")
#    ) % { :num => invoice.unique_number.to_s }
#  end

  def invoice_text(invoice,text)
    i_(invoice,text)
  end

  # Wrapper around _() method, that dynamically replaces occurrences
  # of "invoice" with "quote" (if given a quote)
  def i_(invoice,str)

    # It would be neat do this in more dynamic way,
    # but we need to explicitly mention all string versions
    # (both quote and invoice).
    # It's required by gettext's external tools
    # which need to find them while parsing our source (.rb) files
    quotes_substitutions = {
        N_('Invoice')           => N_('Quote'),
        N_('Invoice:')          => N_('Quote:'),
        N_('Invoice %{num}')    => N_('Quote %{num}'),
        N_('Invoice %{num}:')   => N_('Quote %{num}:'),
        N_('Edit Invoice')      => N_('Edit Quote'),
        N_('It has no customer. Please edit the invoice and add a customer.') => N_('It has no customer. Please edit the quote and add a customer.'),
        N_('It has no line items. Please edit the invoice and add one or more line items.') => N_('It has no line items. Please edit the quote and add one or more line items.'),
        N_('Invoices without a customer cannot be sent.') => N_('Quotes without a customer cannot be sent.'),
        N_('Amount Due:') =>  N_('Total Amount:'),
        N_('Amount Owing:') =>  N_('Total Amount:'),
        N_('Preview Invoice') => N_('Preview Quote'),
        N_('Delete this Invoice') => N_('Delete this Quote'),
        N_('Editing invoice') => N_('Editing quote'),
        N_('Are you sure you want to delete this invoice?') => N_('Are you sure you want to delete this quote?'),
        N_('Invoice has no customer') => N_('Quote has no customer'),
        N_('Invoice has no customer') => N_('Quote has no customer'),
        N_('Edit this invoice') => N_('Edit this quote'),
        N_('New Invoice') => N_('New Quote'),
        N_('Invoice number:') => N_('Quote number:'),
        N_('Invoice number already taken') => N_('Quote number already taken'),
        N_("<p>Wanted invoice number <b><span id='wanted_auto' value='%{wanted}'>%{wanted}</span></b> has already been taken.<br/>Closest available invoice number: <b><span id='available_auto' value='%{available}'>%{available}</span></b><br/>Use this number instead?</p>") => N_("<p>Wanted quote number <b><span id='wanted_auto' value='%{wanted}'>%{wanted}</span></b> has already been taken.<br/>Closest available quote number: <b><span id='available_auto' value='%{available}'>%{available}</span></b><br/>Use this number instead?</p>"),
        N_('This invoice cannot be sent because:') => N_('This quote cannot be sent because:'),
        N_('Invoices must have at least one line item with positive price and quantity before they can be sent.') => N_('Quotes must have at least one line item with positive price and quantity before they can be sent.'),
        N_('Save Invoice') => N_('Save Quote'),
        N_('Send Invoice') => N_("Send Quote"),
        N_('This email and invoice will be sent in the following language') => N_('This email and quote will be sent in the following language'),
        N_('Attach a copy of the invoice as Adobe PDF document') => N_('Attach a copy of the quote as Adobe PDF document'),
        N_('Invoice was successfully created.') => N_('Quote was successfully created.'),
        N_('Invoice was successfully updated.') => N_('Quote was successfully updated.'),
        N_('This invoice was sent using Billing Boss – an online invoice and payment tool that allows small businesses to create, send and track the status of invoices from the same team that developed Simply Accounting. For more information, please visit www.billingboss.com.') => N_('This quote was sent using Billing Boss – an online invoice and payment tool that allows small businesses to create, send and track the status of invoices from the same team that developed Simply Accounting. For more information, please visit www.billingboss.com.'),
        N_('Here is the invoice from %{name}.') => N_('Here is the quote from %{name}.'),
        N_('New invoice from %{sender}') => N_('New quote from %{sender}'),
        N_('To view this invoice online, please go to %{link}') => N_('To view this quote online, please go to %{link}')

    }

    dynamic = invoice.quote? ? quotes_substitutions[str] : str

    raise ArgumentError.new("This string has no Quotes version 1: '#{str}'") unless dynamic

    _( dynamic )
  end

  def logo_or_upload_link(profile)
    result = "<div id='preview_heading_logo'>"
    if profile.logo && profile.logo.image?
       result += image_tag( profile.logo.public_filename, :class=>'company_logo')
    end
    result += "</div>"
    result
  end

  def link_to_customer(invoice)
    invoice.customer ?
      (link_to invoice.customer.name, edit_customer_path(invoice.customer)) :
      ""
  end
end
