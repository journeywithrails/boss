require "#{File.dirname(__FILE__)}/../test_helper"

class FixturesTest < Test::Unit::TestCase
  fixtures :all

  def test_add_valid_helpers
    user = users(:basic_user)
    invoice = add_valid_invoice(user)
    assert invoice.valid?
    assert_equal 1, invoice.line_items.size
    
    line_item = add_valid_line_item(invoice)
    assert line_item.valid?
    assert invoice.valid?

    cust = add_valid_customer(user)
    assert cust.valid?
    assert_equal 1, cust.contacts.size

    
    contact = add_valid_contact(cust)
    assert contact.valid?
    assert cust.valid?
  end

  def test_add_valid_customer_no_contacts
    cust = add_valid_customer(users(:basic_user), {:contacts => false})
    assert cust.valid?
    assert_equal 0, cust.contacts.size
  end

  def test_add_valid_invoice_no_line_items
    invoice = add_valid_invoice(users(:basic_user), {:line_items => false})
    assert invoice.valid?
    assert_equal 0, invoice.line_items.size
  end
  
  def test_add_valid_invoice_and_line_items_results_in_correct_amount_owing
    invoice = add_valid_invoice(users(:basic_user), {:line_items => false})
    assert invoice.valid?
    assert_equal 0, invoice.line_items.size
    line_item = add_valid_line_item(invoice, {:price => 621})
    assert_equal 621, line_item.subtotal, "new line_item subtotal should be 621"
    assert_equal 621, invoice.amount_owing, "invoice amount_owing should be 621"
    
    
    invoice = add_valid_invoice(users(:basic_user), {:line_items => [{:price => 633}]})
    assert invoice.valid?
    assert_equal 633, invoice.amount_owing, "invoice amount_owing should be 633"
  end
end
