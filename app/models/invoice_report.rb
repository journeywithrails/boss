class InvoiceReport < Report
  def json_params
    { 
      :only    => [:invoices, :id, :customer_id,:date,:total_amount,:reference,:subtotal_amount, :tax_1_amount, :tax_2_amount, :discount_amount, :paid_amount, :owing_amount], 
      :methods => [:unique, :customer_name, :meta_status, :brief_meta_status_string],
    }
  end
  
end
