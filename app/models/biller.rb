class Biller < ActiveRecord::Base
  has_one  :user, :dependent => :nullify

  has_many :bookkeeping_contracts, :foreign_key => :bookkeeping_client_id
  has_many :bookkeepers, :through => :bookkeeping_contracts
  
  def method_missing(symbol, *params)
    RAILS_DEFAULT_LOGGER.warn "biller #{id} delegating #{symbol.to_s} to user"
    self.user.send(symbol, *params)
  end
  
  def invoices_calculated
    self.invoices.reject(&:quote?).reject(&:recurring?)
  end

  def total_invoice_amounts
    self.invoices_calculated.inject(BigDecimal.new('0')) do |amt, i|
      amt += i.total_amount
    end
  end
  
  def total_amount_owing
    self.invoices_calculated.inject(BigDecimal.new('0')) do |amt, i|
      amt += i.amount_owing
    end
  end
  
end
