$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'
require File.dirname(__FILE__) + '/acceptance_test_helper'


class ProtectFormstest < SageAccepTestCase
  include AcceptanceTestSession
  fixtures :users
  def setup
    @user = watir_session.with(:basic_user)
    @user.logs_in
  end
  
  def teardown
    @user.teardown
  end
  
  def test_new_invoice_comprehensive
    b = @user.b
    @user.goto(::AppConfig.host.to_s + "/invoices/new?protect=1")
    b.text_field(:id, 'invoice_discount_value').set("1")
    b.text_field(:id, 'invoice_discount_value').set("2")
    b.wait
    
    b.link(:id, 'new_customer').click_no_wait
    sleep 1
    b.wait      
    
    startClicker(b, "Cancel") 
    
    assert b.text_field(:id, 'invoice_discount_value').exists?

    b.link(:id, 'new_customer').click_no_wait
    b.wait
    startClicker(b, "OK") 
    b.wait

    deny b.text_field(:id, 'invoice_discount_value').exists?

  end


end