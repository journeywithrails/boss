require File.dirname(__FILE__) + '/../test_helper'

class InvoiceAwolTest < Test::Unit::TestCase
  def test_should_cache_amounts
    Profile.any_instance.stubs(:tax_1_in_taxable_amount).returns(false)
    invoice = add_valid_invoice(users(:basic_user), {:line_items => [{:price => 100, :quantity => 2}, {:price => 20, :quantity => 5}]})
    invoice.tax_1_rate = 10
    invoice.tax_1_name = "ten"
    invoice.tax_2_rate = 1
    invoice.tax_2_name = "one"
    invoice.discount_value = BigDecimal.new("50")
    invoice.discount_type = Invoice::AmountDiscountType
    invoice.save!
    i2 = Invoice.find(invoice.id)

    assert_equal 30, i2.tax_1_amount, "invoice failed to properly cache tax_1_amount"
    assert_equal 3.0, i2.tax_2_amount, "invoice failed to properly cache tax_2_amount"
    assert_equal 50, i2.discount_amount, "invoice failed to properly cache discount_amount"
    assert_equal 300, i2.subtotal_amount, "invoice failed to properly cache subtotal_amount"
    assert_equal 283.0, i2.total_amount, "invoice failed to properly cache total_amount"
  end
end
