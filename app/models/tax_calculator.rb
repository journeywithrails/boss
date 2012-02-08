# Give me an amount and I will calculate taxes for you.
class TaxSum
  def initialize(tax_calculator)
    @tax_calculator = tax_calculator
  end
  
  def all_taxes(amount)
    sum(@tax_calculator.all_taxes(amount))
  end
  
  def not_included_taxes(amount, only_for=nil)
    sum(@tax_calculator.not_included_taxes(amount, only_for))
  end
  
  def included_taxes(amount)
    sum(@tax_calculator.included_taxes(amount))
  end
  
  protected
  def sum(array)
    array.inject(BigDecimal.new('0')) do |s, tax|
      s+Currency.round(tax.amount)
    end
  end

end

class TaxCalculator
  include Sage::BusinessLogic::Exception
  
  def initialize(taxes)
     @taxes = taxes
     set_effective_rates!
  end
  
  def sum_of
    return TaxSum.new(self)
  end
  
  def all_taxes(amount)
     not_included_taxes(amount) + included_taxes(amount)
  end

  def not_included_taxes(amount, only_for=nil)
     base_amt = self.base(amount)
     if !only_for
       not_included = @taxes.find_all {|tax| not tax.included}
     else
       not_included = @taxes.find_all {|tax| (not tax.included) && (tax.profile_key == only_for)}
     end
     not_included.each do |tax|
       tax.amount = (base_amt * tax.effective_rate)
     end

     not_included
  end

  #Calcluated included taxes from the given amount.
  def included_taxes(amount)
    tax_rate = BigDecimal.new('0')
    # perform approximate base amount calculation
    included = @taxes.find_all {|tax| tax.included}
    included.each do |tax|
      tax_rate += tax.effective_rate
    end
    approx_base = amount / (BigDecimal.new('1.0') + tax_rate)

    #use approximate base to calculate included taxes.
    included.each do |tax|
      tax.amount = approx_base * tax.effective_rate
    end
    included
  end

  protected
  def set_effective_rates!
    @taxes.each do |tax|
      tax.effective_rate = effective_rate!(tax) #,  BigDecimal.new('1.0')
    end
  end
  
  def effective_rate!(tax)
    if tax.effective_rate == :recurse
      raise Error, 'Bad tax on tax association detected: cyclic dependency'
    end
    return 0 if not tax.enabled
    return tax.effective_rate if not tax.effective_rate.nil?
    tax.effective_rate = :recurse

    effective = BigDecimal.new('1.0')
    tax.taxed_on.each do |tax_on|
      
      t = @taxes.select{|t| t.profile_key==tax_on}.first
      raise Error, 'Bad tax on tax association detected: non-existent dependency' if t.nil?
      effective += effective_rate!(t)
    end if tax.taxed_on
    effective * tax.rate * BigDecimal.new('0.01') # convert @rate to actual percentage.
  end

  # Remove all included tax amounts to determine base tax rate.
  def base(amt)
    a = included_taxes(amt)
    base_amt = Currency.round(amt)
    # Back-calculating base amount should eliminate rounding errors in the base.
    a.each do |tax|
       base_amt -= Currency.round(tax.amount)
    end
    base_amt
  end
  
end
