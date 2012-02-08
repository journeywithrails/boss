class LineItem < ActiveRecord::Base
  belongs_to :invoice
  acts_as_list :scope => :invoice
  attr_accessor :row_id
  validates_not_negative :quantity
  
  validate :subtotal_must_be_under_a_million
  def subtotal_must_be_under_a_million
    errors.add('',_('The line item subtotal must be less than 1,000,000')) unless self.subtotal < BigDecimal('1000000')
  end
  
  def subtotal
    return BigDecimal.new("0") if self.price.nil? or self.quantity.nil?
    self.price * self.quantity
  end
  
  #RADAR not sure how dangerous this is. Necessary to prevent holes in forms
  alias_method :old_id, :id
  def id
    return old_id unless old_id.nil?
    'new_object_'+object_id.to_s
  end
  
  def taxable_for?(profile_key)
    return false unless ::Tax::TaxesVersionOne.tax_keys.include?(profile_key)
    return self.send("#{profile_key}_enabled")
  end
end
