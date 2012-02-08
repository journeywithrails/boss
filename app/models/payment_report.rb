class PaymentReport < Report
  def json_params
    { 
      :only    => [:payments, :invoices, :id, :customer_id, :amount, :date],
      :methods => [:customer_name, :invoice_no, :invoice_full_amount, :pay_type_display],
    }
  end
  
end
