
class InvoiceCalculator < SimpleDelegator
  def self.setup_for(invoice)
    if invoice.created_by.nil? or invoice.created_by.profile.nil?
      return self.new(invoice)
    end
    
    before_tax = invoice.discount_before_tax || invoice.created_by.profile.discount_before_tax
    
    if before_tax.nil?
      raise StandardError, 'Bad discount before tax settings'
    end
    if (before_tax)
      DiscountBeforeTaxCalculator.new(invoice)
    else
      DiscountAfterTaxCalculator.new(invoice)
    end
  end

  def calculate_tax_on(amount, only_for=nil)
#    enabled_taxes = taxes.include{|t| t.tax_enabled?}
    tc = TaxCalculator.new(taxes)

    tc.sum_of.not_included_taxes(amount, only_for)
  end

  def calculate_discount_on(amount)
    if self.discount_value.blank? or self.discount_value.zero?
      0
    else
      case self.discount_type
      when Invoice::AmountDiscountType
        #self.discount_value
        amount_after_discount = amount - self.discount_value 
      when Invoice::PercentDiscountType
        amount_after_discount = amount * (1 - (self.discount_value / 100)) 
      else
        raise Sage::BusinessLogic::Exception::UnknownDiscountTypeException
      end
      #RADAR dependency on currency decimal places in db
      amount_after_discount = Currency.round(amount_after_discount)
      amount - amount_after_discount
    end
  end

  #### Stubs
  def discount
    return calculate_discount_on(line_items_total)
  end
  
  # If the invoice is not scoped, tax calculations will not work.
  def tax
    return 0
  end
  
  def total
    line_items_total - discount
  end
  
end
  
class DiscountBeforeTaxCalculator < InvoiceCalculator
  def discount
    calculate_discount_on(line_items_total)
  end

  def tax
    t = BigDecimal.new("0")
    Tax::TaxesVersionOne.tax_keys.each do |k|
      t += calculate_tax_on(line_items_total_for_tax(k), k)
    end
    t
  end
  
  def total
    line_items_total - discount + tax
  end
end

class DiscountAfterTaxCalculator < InvoiceCalculator
  def discount
    calculate_discount_on(line_items_total + tax)
  end

  def tax
    t = BigDecimal.new("0")
    Tax::TaxesVersionOne.tax_keys.each do |k|
      t += calculate_tax_on(line_items_total_for_tax(k), k)
    end
    t
  end
  
  def total
    line_items_total + tax - discount
  end
end
