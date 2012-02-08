module FilterWithInvoice
  protected

  def layout_for_invoice_recipient
    @custom_layout = "main"    
    @printable = true
    @skip_header = true
    @skip_footer = true
    @hide_analytics = true
    if @invoice
      unless @invoice.customer.nil? or @invoice.created_by? current_user
        set_language_from_customer || set_language_from_cookie
      end
    end
    'main'
  end

  def filter_with_invoice
    return @invoice if @invoice
    begin
      ak = AccessKey.find_by_key(access_key)
      if ak.nil?
        render :template => "access/not_found", :status => 404
        false
      elsif not ak.use?
        unable_to_process_page('The access key is no longer valid')
      else
        @invoice = Invoice.find(ak.keyable_id)
        true
      end
    rescue ActiveRecord::RecordNotFound
      render :template => "access/not_found", :status => 404
    end
  end
  
  def set_language_from_customer
    set_locale(@invoice.customer.language)
  end
end
