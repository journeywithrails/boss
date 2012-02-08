require File.dirname(__FILE__) + '/../test_helper'
include Sage::BusinessLogic::Exception

class InvoiceCalculatorTest < Test::Unit::TestCase
  fixtures :invoices
  fixtures :users
  fixtures :customers
  fixtures :configurable_settings

  def test_should_get_taxes
    u = User.find(users(:complete_user).id)
    assert_equal 2, u.taxes.count
    
    i = u.invoices.new
    i.setup_taxes
        
    ic = InvoiceCalculator.setup_for(i)
    
    taxes = ic.taxes
    assert_equal 2, taxes.length
    assert taxes.any?{|t| t.profile_key == 'tax_1'}
    assert taxes.any?{|t| t.profile_key == 'tax_2'}
  end

  def test_should_calculate_discount_before_tax
    u=users(:complete_user)
    i=u.invoices.new
    i.setup_taxes
    assert_equal u.id, i.created_by.id

    li = i.line_items.new
    li.price = BigDecimal.new('100')
    li.quantity = BigDecimal.new('1')
    i.line_items = [li] #not sure why, but without this line i.line_items returns blank
    i.discount_type = Invoice::PercentDiscountType
    i.discount_value = BigDecimal.new('10')
    i.created_by.expects(:profile).returns(OpenStruct.new({:discount_before_tax => true})).at_least_once

    ic = InvoiceCalculator.setup_for(i)
    assert_equal DiscountBeforeTaxCalculator, ic.class
    discount_amount = ic.discount
    tax_amount = ic.tax
    total = ic.total
    
    assert_equal BigDecimal.new('10'), discount_amount
    assert_equal BigDecimal.new('13'), tax_amount
    assert_equal BigDecimal.new('103'), total
  end
  
  def test_should_calculate_discount_after_tax
    u=users(:complete_user)
    i = u.invoices.new
    i.setup_taxes
    li = i.line_items.new
    li.price = BigDecimal.new('100')
    li.quantity = BigDecimal.new('1')
    i.line_items = [li] #not sure why, but without this line i.line_items returns blank
    
    assert_equal u.id, i.created_by.id
    
    i.discount_type = Invoice::PercentDiscountType
    i.discount_value = BigDecimal.new('10')
    i.created_by.expects(:profile).returns(
      OpenStruct.new({:discount_before_tax => false})
      ).at_least_once
    
    ic = InvoiceCalculator.setup_for(i)
    assert_equal DiscountAfterTaxCalculator, ic.class
    discount_amount = ic.discount
    tax_amount = ic.tax
    total = ic.total
    
    assert_equal BigDecimal.new('13'), tax_amount
    assert_equal BigDecimal.new('11.3'), discount_amount
    assert_equal BigDecimal.new('101.7'), total
  end
  
  def test_should_not_calculate_tax_on_unscoped_invoice
    i=Invoice.new
    
    i.expects(:line_items_total).returns(BigDecimal.new('100')).at_least_once
    i.discount_type = Invoice::PercentDiscountType
    i.discount_value = BigDecimal.new('10')
    
    ic = InvoiceCalculator.setup_for(i)
    assert_equal InvoiceCalculator, ic.class
    discount_amount = ic.discount
    tax_amount = ic.tax
    total = ic.total
    
    assert_equal BigDecimal.new('10'), discount_amount
    assert_equal BigDecimal.new('0'), tax_amount
    assert_equal BigDecimal.new('90'), total
  end
  
  def test_should_raise_exception_if_before_tax_setting_is_nil
    u = User.find(users(:complete_user).id)
    i=u.invoices.new
    i.expects(:discount_before_tax).returns(nil)
    i.created_by.profile.expects(:discount_before_tax).returns(nil)
    
    assert_raises StandardError do
      InvoiceCalculator.setup_for(i)
    end
  end
  
end