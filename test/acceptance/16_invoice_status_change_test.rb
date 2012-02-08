$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'

# Test cases for User Story 16
# Invoice status changes after saving and senting
class InvoiceStatusChangeTest < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users, :invoices
  
  def setup
    @user = watir_session.with(:basic_user)
    @user.logs_in
    start_email_server
  end
  
  def teardown
    end_email_server
    @user.teardown
  end

  def test_invoice_after_save_status_change
    # Verify that 1 invoice is addded
    assert_difference( 'Invoice.find(:all).size', 1) do
      @user.creates_new_invoice
      @user.enter_new_customer( 
          :name => "Test 16 Customer"
      ) 
      @user.populate(@user.b.text_field(:id, "invoice_unique"), ("Inv-000"))
      @user.populate(@user.b.text_field(:id, "invoice_description"), ("Description for Invoice"))
  	  
      # first line item is displayed automatically, so edit
      @user.edits_line_item(
        1,
        :unit => "Item A1",
  			:description => "Description for Item A1",
  			:quantity => "10.0",
  			:price => "5.5")
  	  
      @user.and_submits
    end
    
    @user.b.wait

    #tries to find the draft status string
    assert @user.b.html.include?("Draft Invoice"), "Cannot find the draft status string on invoice"
        

    #send the invoice
    @user.b.link(:id, "show-send-dialog-btn").click
    Watir::Waiter.new(12).wait_until do
      @user.b.text_field(:id, "delivery_recipients").exists?
    end
    
    @user.populate(@user.b.text_field(:id, "delivery_recipients"), ("test@billingboss.com"))


    deliverable_id = @user.hidden(:id, "delivery_deliverable_id").value
    message_id = @user.wait_for_delivery_of(deliverable_id, "send invoice") do    
      @user.element_by_xpath("id('send-dialog-send-button')").click # don't ask for button directly, because on firefox ext wraps button in a table, and the table gets the id not the button element
    end

    assert @user.b.html.include?("Outstanding Invoice"), "Cannot find the Outstanding status string on invoice"
  end
  
  
end
