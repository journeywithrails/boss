$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'


class InvoiceNumberingTest < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users
  fixtures :invoices
  
  def setup
    @user = watir_session.with(:user_without_invoices)
    @user.logs_in
  end
  
  def teardown
    @user.teardown
  end
 
  def test_entered_number_is_saved_and_next_displayed
    b = @user.b
    @user.creates_new_invoice
    b.wait
    @user.submits
    b.wait
    
    num = b.span(:id, 'invoice_unique').text.to_i
    assert_equal 1, num
    @user.creates_new_invoice
    b.wait
    num2 = b.text_field(:id, 'invoice_unique').value.to_i
    assert_equal 2, num2
  end
  
  def test_flash_on_custom_error
    b = @user.b
    @user.creates_new_invoice
    b.wait
    @user.populate(b.text_field(:id, 'invoice_unique'),"asdf")
    @user.submits
    b.wait
    num = b.span(:id, 'invoice_unique').text
    assert_equal "asdf", num
    
    @user.creates_new_invoice
    b.wait
    @user.populate(b.text_field(:id, 'invoice_unique'),"asdf")
    @user.submits
    
    sleep 23
    errorstr = b.div(:id, 'errorExplanation').text
    

    assert (errorstr.include?("Unique name has already been taken"))
#    assert_equal "1 error prohibited this invoice from being saved\r\nThere were problems with the following fields:\r\nUnique name has already been taken", errorstr
    
  end
  
  def test_popup
    b = @user.b
    @user.creates_new_invoice
    b.wait
    control_text = b.div(:id, 'invoice_container').text
    @user.submits
    b.wait
    
    @user.creates_new_invoice
    b.wait
    @user.populate(b.text_field(:id, 'invoice_unique'), "1")
    @user.submits
    b.wait
    
    assert_equal control_text, b.div(:id, 'invoice_container').text
    header_text = b.span(:class, 'x-window-header-text').text
    assert_equal header_text, "Invoice number already taken"
    wanted_auto = b.span(:id, 'wanted_auto').text.to_i
    available_auto = b.span(:id, 'available_auto').text.to_i
    assert_equal wanted_auto, 1
    assert_equal available_auto, 2
    
    b.div(:id, "auto-number-taken").button(:text, "No").click
    b.wait
    assert_equal "", b.text_field(:id, 'invoice_unique').text
    
    @user.populate(b.text_field(:id, 'invoice_unique'), "1")
    @user.submits
    b.wait
    b.div(:id, "auto-number-taken").button(:text, "Yes").click
    b.wait
    
    num = b.span(:id, 'invoice_unique').text.to_i
    assert_equal 2, num
    
  end
 
end