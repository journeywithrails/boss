
$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') if $0 == __FILE__
require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/sage_accep_test_case'
require File.dirname(__FILE__) + '/acceptance_test_helper'
require File.dirname(__FILE__) + '/helpers/payment_acceptance_helper'

class MonerisPaymentTest < SageAccepTestCase
  include AcceptanceTestSession
  include PaymentAcceptanceHelper
  
  fixtures :users
  fixtures :invoices
  fixtures :user_gateways
  fixtures :configurable_settings
  fixtures :access_keys

  def setup
    @session=watir_session
    start_email_server
  end
  
  def teardown
   end_email_server
  end


 #go through the entire flow from setting up gateway to customer paying the invoice
  def test_success_cc_payment_page
    @u = users(:user_without_sps_gateway_settting)
    @user = watir_session.with(:user_without_sps_gateway_settting)
    @user.logs_in

    @invoice = invoices(:invoice_moneris_payment_cc)
    
    
    b = @user.b
    add_sps_cc_profile(:user_without_sps_gateway_settting)
    @url = send_invoice(@invoice.id, true, true, true)
  
    total = b.span(:id, "invoice_total").text
    assert_equal "10.00 CAD", total

    link = b.link(:text, "Pay Invoice")
    link.click
    b.wait
    
    b.button(:value, "Pay Now").click
    b.wait
    assert b.html.include?("12 errors"), "cannot find validation error message"
    
    pay = Payment.find(:first, :conditions => {:pay_type => 'moneris' })
    assert_equal 'created', pay.status

    b.text_field(:id, 'card_number').value=('4242424242424242')
    b.text_field(:id, 'card_first_name').value=('Payer First')
    b.text_field(:id, 'card_last_name').value=('Payer Last')
    b.select_list(:id, 'card_year').option(:text, '2012').select
    b.text_field(:id, 'card_verification_value').value=('123')
    

    b.text_field(:id, 'billing_address_name').value=('Payer Name')
    b.text_field(:id, 'billing_address_address1').value=('Payer Address1')
    b.text_field(:id, 'billing_address_city').value=('Payer City')
    b.select_list(:id, 'billing_address_state').select('BC - British Columbia')
    b.text_field(:id, 'billing_address_zip').value=('12345')
    b.text_field(:id, 'billing_address_phone').value=('123-456-7890')
    b.text_field(:id, 'billing_address_email').value=('test@test.com')
    
    b.button(:value, "Pay Now").click
    b.wait
    assert b.html.include?("successfully recorded")
    pay = Payment.find(:first, :conditions => {:pay_type => 'moneris' })
    assert_equal 'cleared', pay.status
    
    @user.goto(@url)
    b.wait
    sleep 3
    #verify pay invoice link does not exist
    assert !b.html.include?("Pay Invoice") , "Paid invoice link found for fully paid invoice."
    inv = Invoice.find(@invoice.id)
    assert_equal "paid", inv.status
    assert_equal 0.0, inv.owing_amount
    assert_equal inv.total_amount, inv.paid_amount
    
   
    @u = nil
    @user.teardown    
  end

#testing rejected payment (based on cent value != .00)
  def test_rejected_cc_simulation
    @u = users(:user_without_sps_gateway_settting)
    @user = watir_session.with(:user_without_sps_gateway_settting)
    @user.logs_in
    
    
    b = @user.b
    @invoice = invoices(:invoice_moneris_payment_cc_two)
    add_sps_cc_profile(:user_without_sps_gateway_settting)
    @url = send_invoice(@invoice.id, true, true, true)
  
    total = b.span(:id, "invoice_total").text
    assert_equal "1.50 CAD", total

    link = b.link(:text, "Pay Invoice")
    link.click
    b.wait
    
    b.button(:value, "Pay Now").click


    b.text_field(:id, 'card_number').value=('4242424242424242')
    b.text_field(:id, 'card_first_name').value=('Payer First')
    b.text_field(:id, 'card_last_name').value=('Payer Last')
    b.select_list(:id, 'card_year').option(:text, '2012').select
    b.text_field(:id, 'card_verification_value').value=('123')
    

    b.text_field(:id, 'billing_address_name').value=('Payer Name')
    b.text_field(:id, 'billing_address_address1').value=('Payer Address1')
    b.text_field(:id, 'billing_address_city').value=('Payer City')
    b.select_list(:id, 'billing_address_state').select('BC - British Columbia')
    b.text_field(:id, 'billing_address_zip').value=('12345')
    b.text_field(:id, 'billing_address_phone').value=('123-456-7890')
    b.text_field(:id, 'billing_address_email').value=('test@test.com')

    b.button(:value, "Pay Now").click
    b.wait
    assert b.html.include?("Declined")
    pay = Payment.find(:first, :conditions => {:pay_type => 'moneris' })
    assert_equal 'error', pay.status
    
    @user.goto(@url)
    b.wait
    sleep 3
    #verify pay invoice link does not exist

    inv = Invoice.find(@invoice.id)
    assert_equal "sent", inv.status
    assert_equal "1.5", inv.owing_amount.to_s
    assert_equal 0, inv.paid_amount
    
   
    @u = nil
    @user.teardown    
  end
  
  def test_call_for_authorization_cc_simulation
    @u = users(:user_without_sps_gateway_settting)
    @user = watir_session.with(:user_without_sps_gateway_settting)
    @user.logs_in
    
    
    b = @user.b
    add_sps_cc_profile(:user_without_sps_gateway_settting)
    @invoice = invoices(:invoice_moneris_payment_need_to_call_for_authorization)

    @url = send_invoice(@invoice.id, true, true, true)
  
    total = b.span(:id, "invoice_total").text
    assert_equal "1.01 CAD", total

    link = b.link(:text, "Pay Invoice")
    link.click
    b.wait
    
    b.button(:value, "Pay Now").click


    b.text_field(:id, 'card_number').value=('4242424242424242')
    b.text_field(:id, 'card_first_name').value=('Payer First')
    b.text_field(:id, 'card_last_name').value=('Payer Last')
    b.select_list(:id, 'card_year').option(:text, '2012').select
    b.text_field(:id, 'card_verification_value').value=('123')
    

    b.text_field(:id, 'billing_address_name').value=('Payer Name')
    b.text_field(:id, 'billing_address_address1').value=('Payer Address1')
    b.text_field(:id, 'billing_address_city').value=('Payer City')
    b.select_list(:id, 'billing_address_state').select('BC - British Columbia')
    b.text_field(:id, 'billing_address_zip').value=('12345')
    b.text_field(:id, 'billing_address_phone').value=('123-456-7890')
    b.text_field(:id, 'billing_address_email').value=('test@test.com')

    b.button(:value, "Pay Now").click
    b.wait
    assert b.html.include?("Call for authorization")
    pay = Payment.find(:first, :conditions => {:pay_type => 'moneris' })
    assert_equal 'error', pay.status
    
    @user.goto(@url)
    b.wait
    sleep 3
    #verify pay invoice link does not exist

    inv = Invoice.find(@invoice.id)
    assert_equal "sent", inv.status
    assert_equal "1.01", inv.owing_amount.to_s
    assert_equal 0, inv.paid_amount
    
   
    @u = nil
    @user.teardown    
  end
  
  def add_sps_cc_profile(usr=:basic_user)

    u = users(usr)
    u.profile.company_name = "Some name"
    u.profile.company_address1 = "Some addres"
    u.profile.company_city = "Vancouver"
    u.profile.company_state = "BC"
    u.profile.company_country = "CA"
    u.profile.company_postalcode = "V1V 1V1"
    u.profile.company_phone ="555-1234"
    u.profile.save!
    u.save!
    u

    @user.goto_profile_url
    @user.b.link(:id, "user_payments_link").click
    @user.b.wait
 
    @user.b.radio(:xpath, "//input[@value='moneris']").click
    @user.b.wait
    sleep 3
    @user.b.text_field(:id, 'user_gateways[moneris][login]').value=("store1")
    @user.b.text_field(:id, 'user_gateways[moneris][password]').value=("yesguy")
    @user.button(:name, "commit").click
    @user.b.wait

  end
  
  def send_invoice(id, goto_payment, logout, set_cc_payment_method)
    b = @user.b
    @user.goto_invoice_url(id)
    
    @user.wait

      @user.checkbox(:id, 'pay_by_visa').set
      @user.wait
      @user.checkbox(:id, 'pay_by_master').set
      @user.wait
      @user.button(:value, 'Save').click
      @user.wait      
     

    sleep 3
    @user.link(:id, 'show-send-dialog-btn').click
    
    @user.wait
    @user.text_field(:id, 'delivery_recipients').value=('moneris_client@ex.com')
    @key = @user.link(:id, 'invoice_link').name    
    @user.button(:value, 'Send').click
    @user.wait

    if logout
      @user.goto("#{::AppConfig.host}/logout")
      b.wait
    end
    if goto_payment
      @url= get_payment_url
      @user.goto(@url)
      b.wait
    end
    return @url
  end
  
end