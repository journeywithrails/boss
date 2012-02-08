module BookkeepingClientsHelper
  
  def total_invoice_amounts
    @client.total_invoice_amounts
  end
  
  def total_amount_owing
    @client.total_amount_owing
  end
  
end
