$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'


#test cases invoice removal
class InvoiceRemovalTest < SageAccepTestCase
  
  include AcceptanceTestSession
  fixtures :users, :invoices
  
  def setup
    @basic_user = watir_session.with(:basic_user)
    @basic_user.logs_in    
  end
  
  def teardown 
    @basic_user.teardown
  end

  def test_should_remove_an_existing_invoice
    #save a new invoice first
    invoice = nil
    assert_difference 'Invoice.count', 1 do
      @basic_user.creates_new_invoice
      @basic_user.enter_new_customer( 
          :name => "Test 5 Customer 1"
      )        
      @basic_user.submits
      invoice = Invoice.find(:first, :order => 'id desc')      
    end
    
    #remove it
    assert_difference 'Invoice.count', -1 do
      @basic_user.removes_invoice(invoice.id)
    end
  end
  

  def test_should_remove_an_existing_invoice_from_list
    @browser = @basic_user.displays_invoice_list.b
    
    #simulate a link click
    if (WatirBrowser.ie?) 
      assert_difference 'Invoice.count', -1 do
        @browser.link(:id, "destroy_1").click_no_wait
        #@browser.click_jspopup_button("OK")
        startClicker(@browser, "OK")
        @browser.wait
      end
    else
      assert_difference 'Invoice.count', -1 do
        @browser.startClicker("OK")
        @browser.link(:id, "destroy_1").click
      end
    end
  end
  
  def test_should_remove_an_existing_invoice_while_editing
    invoice = nil
    @browser = @basic_user.b
    assert_difference 'Invoice.count', 1 do
      @basic_user.creates_new_invoice
      @basic_user.enter_new_customer( 
          :name => "Test 5 Customer 2"
      )
      @basic_user.submits
      invoice = Invoice.find(:first, :order => 'id desc')      
    end
    
    #remove it
    @basic_user.edits_invoice(invoice.id)
    if (WatirBrowser.ie?) 
      assert_difference 'Invoice.count', -1 do
        @browser.link(:id, 'destroy').click_no_wait
        startClicker(@browser, "OK")
        @browser.wait
      end            
    else
      assert_difference 'Invoice.count', -1 do
        @browser.startClicker("OK")
        @browser.link(:id, 'destroy').click
      end
    end
  end
end
