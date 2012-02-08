$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'

# Test cases for User Story 2
# User can create a new invoice from an edit invoice screen
class InvoiceCanNew < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users, :invoices
  
  def setup
    @user = watir_session.with(:user_without_profile)
    @user.logs_in
  end
  
  def teardown
    @user.teardown
  end
  
  
  def test_new_invoice_link_exists
    # add one invoice
    @user.creates_new_invoice
    @user.b.text_field(:id, "invoice_description").set("Original description for this Invoice")
    @user.enter_new_customer( 
        :name => "Test 2 Customer"
    )    
    @user.and_submits
    
    # gets id
    id_last_invoice = Invoice.find(:first, :order => "id DESC").id
    
    # edits invoice
    @user.edits_invoice(id_last_invoice)

    link_new = @user.b.link(:id , "new_invoice") 
    #see if the element exists
    assert_nothing_raised do
      link_new.text
    end
  end

end